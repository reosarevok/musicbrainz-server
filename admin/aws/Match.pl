#!/home/httpd/musicbrainz/mb_server/cgi-bin/perl -w
# vi: set ts=4 sw=4 :
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 1998 Robert Kaye
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   $Id$
#____________________________________________________________________________

use FindBin;
use lib "$FindBin::Bin/../../cgi-bin";

use strict;
use DBDefs;
use Getopt::Long;
use String::Unicode::Similarity;
use Time::HiRes qw( usleep gettimeofday tv_interval );
use LWP::UserAgent;
use MusicBrainz;
use Artist;
use Album;
use SearchEngine;
use Text::Unaccent;
use Image::Info qw( image_info );
use Net::Amazon;

# This is a fairly important value, set it too low and you won't match all albums when an artist
# has 10 * pages albums.  Set it too high and it can take a long time to go through all the pages 
# for an artist with lots of matches, i.e. Artist = "W"
# I'm picking 25 because of artists like Tangerine Dream who have a ton of albums (205 results)
use constant MAX_PAGES_PER_ARTIST => 25;

use constant MODE_FIND       => 1;
use constant MODE_UPDATE     => 2;
use constant MODE_DAILY      => 3;
use constant MODE_SINGLE     => 4;
use constant MODE_ALL		 => 5;

my $verbose = -t;
my $summary = -t;

# What dataset to process
my $mode = MODE_FIND;
# How much of that set to process
my $percent = undef;
my $limit = undef;
my $various = undef;

# Summary fields
my $start_time = time;
my $artists_processed = 0;
my $va_processed = 0;
my $queries_sent = 0;

# Amazon query object
my $am = Net::Amazon->new( 
	token => &DBDefs::AWS_DEVELOPER_ID,
	max_pages => MAX_PAGES_PER_ARTIST,
);

sub IsValidImage
{
    my ($url) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $response = $ua->get($url);
    if ($response->is_success)
    {
    	my $content = $response->content;
    	my $info = image_info(\$content);
    	if ($info->{file_ext} =~ /jpg|gif|png/)
    	{
            return 0 if ($info->{width} <= 1 || $info->{height} <= 1);
            return 1;
        }
    } 

    return 0;
}

sub CompareName
{
    my ($search, $A, $B) = @_;
    my ($tokb, $toka);

    $tokb = join '', @{($search->Tokenize($B))[1]};
    $toka = join '', @{($search->Tokenize($A))[1]};

    return similarity($tokb, $toka);
}

sub CompareAlbumName
{
    my ($search, $amazon, $mb, $chopit) = @_;
    my ($chopmb, $chopam);

    if ($chopit)
    {
        $mb =~ s/\s*\(.+?\)\s*$//;
        $amazon =~ s/\s*\[.+?\]\s*$//;
        $amazon =~ s/\s*\(.+?\)\s*$//;
    }

    return CompareName($search, $amazon, $mb);
}

sub CompareTrackNames
{
	my ($search, $amTracks, $mbTracks, $va) = @_;
	my ($allAm, $allMb, $tokb, $toka);
	
	# Sometimes we get no track results
	# Net::Amazon sometimes puts an undef value in an array (bug?) so check every item
	foreach (@{$amTracks})
	{
		return 0 unless defined;
	}
	
	# We assume that if the number of tracks doesn't match, it's not a match
	return 0 unless (scalar @{$amTracks} == scalar @{$mbTracks});
	
	foreach my $track (@{$mbTracks}) {
		if ($va)
		{
			# Amazon VA listings appear to be in "name - artist" format
			$allMb .= $track->GetName() . " - " . $track->GetArtistName();
		}
		else
		{
			$allMb .= $track->GetName();
		}
	}
	$allAm = join '', @{$amTracks} if (scalar @{$amTracks});

	return CompareName($search, $allAm, $allMb);
}

# MatchVariousArtists is a bit of duplicated code, but keeps %album_data from containing
# thousands of albums which would greatly slow down the track name matching process
sub MatchVariousArtists
{
	my ($search, $albums) = @_;
	my ($album, %matched);
	my (%album_data, %potential_matches);
	my ($response, $prop, $url);
	
	print "\n" if ($verbose > 2);
	
	# For VA albums, we do a keyword search, 1 per album name
	foreach my $album (@{$albums}) {
		if ($album->GetArtist() == &ModDefs::VARTIST_ID)
		{
			++$va_processed;
			print "  VA Album " . $album->GetName() . ": \n" if ($verbose > 2);
			my $albumName = $album->GetName();
			$albumName =~ s/\s*\(.+?\)\s*$//;
			
			my $t0 = [gettimeofday];
			$response = $am->search(
	    		keyword => unac_string('UTF-8', $albumName),
	    		mode => 'music',
	    	);
	    	++$queries_sent;

			# This is to prevent sending more than 1 query per second to Amazon, as per their TOS
            my $t1 = [gettimeofday];
            my $dur = (1.0 -  tv_interval($t0, $t1)) * 1000000;
            usleep($dur) unless $dur < 0;
	    	
	    	if (!$response->is_success())
	    	{
	    		# print "    Error: " . $response->message() . "\n" if ($verbose > 2);
	    		next;
	    	} 
	    		    	
	    	# Convert returned Amazon data into hash
	    	# We need to keep a counter to use in the hash, because it's possible
			# to have multiple VA albums with the same name, so using the name as the hash key won't work
	    	my $count = 0;
	    	foreach $prop ($response->properties())
	    	{
	    		next unless ($prop->Catalog() =~ /Music|Classical/);
	    	
			    $url = (IsValidImage($prop->ImageUrlMedium())) ? $prop->ImageUrlMedium() : "";
		    	$url =~ s/^http:\/\/images.amazon.com//;
		    	
		    	# upc, release_date are for future use
			    my $key = ++$count . "=" . $prop->album();
		    	$album_data{$key} = {
		    		artist => $prop->artist(),
		    		album => $key,
		    		asin => $prop->Asin(),
		    		url => $url,
		    		upc => $prop->upc(),
		    		release_date => $prop->ReleaseDate(),
					tracks => [ $prop->tracks() ],
		    		matched => 0,
		    	};
		    }
		    
            my ($best, $bestalbum, $tokam, $tokmb);
			my $sim = 0;
			
            # VA albums only use track-level matching

            $best = 0;
            $bestalbum = 0;
            foreach my $amAlbum (keys %album_data)
            {
            	# VA keys have numbers in front, so strip them out
            	my $amAlbumName = $amAlbum;
            	$amAlbumName =~ s/^\d+=//;
            	
        		$sim = CompareTrackNames(
        			$search,
        			$album_data{$amAlbum}->{tracks},
        			[ $album->LoadTracksFromMultipleArtistAlbum() ],
        			1,
        		);

                if ($sim >= $best)
                {
                    $best = $sim;
                    $bestalbum = $amAlbum;
                }
				
				# Store all possible >80% Amazon matches for an MB album.  This will let us
                # choose the match with an image if we get more than 1 match.
				if ($sim > .8)
				{
					$album_data{$amAlbum}->{sim} = $sim;
					push @{$potential_matches{$album}}, $album_data{$amAlbum};
				}
            }
            if ($best > .8)
            {
            	# if the best match doesn't have an image, check through the other possible matches
            	unless ($album_data{$bestalbum}->{url} ne '')
            	{
            		my $oldBest = $best;
            		$best = 0;
					foreach my $possible (@{$potential_matches{$album}})
					{
	            		if (exists $possible->{url} && $possible->{url} ne '') {
	            			if ($possible->{sim} >= $best)
	            			{
            					$bestalbum = $possible->{album};
            					$best = $possible->{sim};
            				}
            			}
            		}
            		# if we didn't find anything, reset the best value
            		$best = $oldBest unless ($best);
            	}
            	
            	my $bestAlbumName = $bestalbum;
            	$bestAlbumName =~ s/^\d+=//;
                $matched{$album} = [ $bestAlbumName, $best, $album_data{$bestalbum}->{asin},
                                     $album_data{$bestalbum}->{url} ];
                $album_data{$bestalbum}->{matched}++;
			}

			if ($verbose > 2)
			{
				if (exists $matched{$album})
				{
				   printf "    OK: %3d%% %s (%d) -- %s (%s) %s\n", 
				       $matched{$album}->[1] * 100, 
				       $album->GetName(), $album->GetId(), 
				       $matched{$album}->[0], $matched{$album}->[2],
				       ($matched{$album}->[3] eq '') ? "no image" : "";
				}
			}
		}
	}
	
	return %matched;
}

sub MatchArtist
{
    my ($dbh, $artist, $artistid) = @_;
    my ($album, $count, %matched);
	my ($ar, @albums, $search, %album_data, %potential_matches);

    print localtime() . " : Matching $artist ($artistid): "
		if $verbose;
	++$artists_processed;

    $search = SearchEngine->new($dbh);
    $ar = Artist->new($dbh);
    $ar->SetId($artistid);

    if ($various)
	{
		@albums = $ar->GetAlbums();
	}
	else
	{   
    	@albums = $ar->GetAlbums(1);
    }
    
	# If invoked via --single we need to check that the artist has at least
	# one album
	if (not @albums)
	{
		print "artist has no albums - skipping\n"
			if $verbose;
		return (0, "");
	}
	
    %matched = MatchVariousArtists($search, \@albums) if ($various);

    $count = 0;
    
    ++$queries_sent;

	# For Non-VA albums, we do an artist search
    my $response = $am->search( 
    	artist => unac_string('UTF-8', $artist),
    );
    
    if (!$response->is_success())
    {
		# print "  Error: " . $response->message() . "\n" if ($verbose > 2);
		
		# Only return if VA match didn't find anything too
		unless (scalar keys %matched)
		{
			print "no Amazon albums found\n" if ($verbose);
			return (0, "");
		}
    }
    
    # Convert returned Amazon data into a hash data format we can use
    foreach my $prop ($response->properties())
    {
    	
    	# Sometimes Amazon will return book results even though we are searching in music, so let's skip them
    	# This happens for example on Jeffrey Foucault
    	next unless ($prop->Catalog() =~ /Music|Classical/);
    	
    	my $url = (IsValidImage($prop->ImageUrlMedium())) ? $prop->ImageUrlMedium() : "";
    	$url =~ s/^http:\/\/images.amazon.com//;
    	
    	# upc, release_date are for future use
    	$album_data{$prop->album()} = {
    		album => $prop->album(),
    		asin => $prop->Asin(),
    		url => $url,
    		upc => $prop->upc(),
    		release_date => $prop->ReleaseDate(),
			tracks => [ $prop->tracks() ],
    		matched => 0,
    	};
    }

    for(my $chop = 0; $chop < 3; $chop++)
    {
        foreach $album (@albums)
        {
            my ($best, $bestalbum, $tokam, $tokmb);
			my $sim = 0;
			
			# Skip all VA albums, they are handled in MatchVariousArtists
			next if ($album->GetArtist() == &ModDefs::VARTIST_ID);
			
            # If this album had already been matched, skip it
            # The exception to this rule is if we got a match without an image.  In this case
            # we want to run a deeper match to see if there are multiple copies of an album and
            # one has an image.  Ex: Tangerine Dream - Miracle Mile has 2 listings in Amazon, 
            # the better match has no image, and the other one does have an image.
            next if (exists $matched{$album} && $matched{$album}->[3] ne '');
            
            $best = 0;
            $bestalbum = 0;
            foreach my $amAlbum (keys %album_data)
            {
            	# VA keys have numbers in front, so strip them out
            	my $amAlbumName = $amAlbum;
            	$amAlbumName =~ s/^\d+=//;
            	
            	if ($chop == 2)
            	{
            		$sim = CompareTrackNames(
            			$search,
            			$album_data{$amAlbum}->{tracks},
            			$album->GetTracks(),
            			"",
            		);
            	}
            	else
            	{
					$sim = CompareAlbumName($search, $amAlbumName, $album->GetName(), $chop);
				}
                if ($sim >= $best)
                {
                    $best = $sim;
                    $bestalbum = $amAlbum;
                }
				
				# Store all possible >80% Amazon matches for an MB album.  This will let us
                # choose the match with an image if we get more than 1 match.
				if ($sim > .8)
				{
					$album_data{$amAlbum}->{sim} = $sim;
					push @{$potential_matches{$album}}, $album_data{$amAlbum};
				}
            }
            if ($best > .8)
            {
            	# if the best match doesn't have an image, check through the other possible matches
            	unless ($album_data{$bestalbum}->{url} ne '')
            	{
            		my $oldBest = $best;
            		$best = 0;
					foreach my $possible (@{$potential_matches{$album}})
					{
	            		if (exists $possible->{url} && $possible->{url} ne '') {
	            			if ($possible->{sim} >= $best)
	            			{
            					$bestalbum = $possible->{album};
            					$best = $possible->{sim};
            				}
            			}
            		}
            		# if we didn't find anything, reset the best value
            		$best = $oldBest unless ($best);
            	}
            	
                $matched{$album} = [ $bestalbum, $best, $album_data{$bestalbum}->{asin},
                                     $album_data{$bestalbum}->{url} ];
                $album_data{$bestalbum}->{matched}++;
            }
        }

		if ($verbose > 2)
		{
	       print "Pass $chop: " . scalar(keys %matched) . " matches:\n";
	       foreach $album (@albums)
	       {
	           if (exists $matched{$album})
	           {
	               printf "   OK: %3d%% %s (%d) -- %s (%s) %s\n", 
	                   $matched{$album}->[1] * 100, 
	                   $album->GetName(), $album->GetId(), 
	                   $matched{$album}->[0], $matched{$album}->[2],
	                   ($matched{$album}->[3] eq '') ? "no image" : "";
	           }
	       }
		}
    }

	# print "MB albums not matched:\n";
    $count = 0;
    foreach $album (@albums)
    {
        if (!exists $matched{$album})
        {
			# printf "  %s (%d)\n", $album->GetName(), $album->GetId();
            # Add an empty record to note that we've looked at this album and found nothing.
            $matched{$album} = [ '', 0, '', '' ];
        }
        else
        {
            $count++ 
        }
    }
    if (scalar(keys %album_data) == 0)
    {
        print "Zero albums returned\n"
			if $verbose;
    }
    else
    {
        printf "MB: %d of %d (%.2f%%)",
			$count, scalar(@albums), $count * 100 / scalar(@albums),
			if $verbose;
    }
 
	# print "Amazon albums not matched:\n";
    $count = 0;
    foreach $album (keys %album_data)
    {
        if ($album_data{$album}->{matched})
        {
           $count++ 
        }
        else
        {
			# printf "  %s %s\n", $album_data{$album}->{asin}, $album;
        }
    }
    # This AM number is not accurate with VA matches
#    if (scalar(keys %album_data) != 0)
#    {
#        printf " AM: %d of %d (%.2f%%)\n",
#            $count, scalar(keys %album_data), $count * 100 / scalar(keys %album_data),
#			if $verbose;
#    }

	print "\n";

    my ($sql);
   
    $sql = Sql->new($dbh);

    $sql->Begin();
    eval 
    {
        foreach $album (@albums)
        {
            if (exists $matched{$album})
            {
				printf "DB UPDATE: album=%d asin=%s url=%s\n",
					$album->GetId,
					$matched{$album}->[2],
					$matched{$album}->[3],
					if 0;

                 $sql->Do("UPDATE album_amazon_asin SET asin = ?, coverarturl = ?, lastupdate = now() WHERE album = ?", 
                         $matched{$album}->[2], $matched{$album}->[3], $album->GetId())
                 or
                 $sql->Do("INSERT INTO album_amazon_asin (asin, coverarturl, album) values (?, ?, ?)", 
                         $matched{$album}->[2], $matched{$album}->[3], $album->GetId())
            }
        }
    };
    if ($@)
    { 
        print localtime() . " : Returning error: $@\n",
			if $verbose;
        $sql->Rollback();
        return (0, $@);
    }
    else
    {
        $sql->Commit();
    }

    return ($count, "");
}

sub MatchAlbums
{
    my ($dbh, $mode, $percent, $limit) = @_;

	my $sth;

    if ($mode == MODE_FIND)
    {
        $sth = $dbh->prepare(qq|select distinct ar.id, ar.name 
                                       from artist ar, album al 
                                  left join album_amazon_asin aaa on aaa.album = al.id 
                                 where aaa.album IS NULL and al.artist = ar.id 
                                 order by ar.id|);
    }
    elsif ($mode == MODE_UPDATE)
    {
        $sth = $dbh->prepare(qq|select ac.id, ac.name, sum(ac.with_asin) as withasin, sum(ac.without_asin) as withoutasin 
                                  from (
                                           select ar.id, ar.name, 0 as with_asin, count(ar.id) as without_asin 
                                             from artist ar, album al, album_amazon_asin aaa 
                                            where aaa.asin = '' and aaa.album = al.id and al.artist = ar.id 
                                            group by ar.id, ar.name 
                                        union 
                                            select ar.id, ar.name, count(ar.id) as with_asin, 0 as without_asin 
                                              from artist ar, album al, album_amazon_asin aaa 
                                             where aaa.asin != '' and aaa.album = al.id and al.artist = ar.id 
                                             group by ar.id, ar.name
                                       ) as ac 
                                 group by ac.id, ac.name order by ac.id|);
    }
    elsif ($mode == MODE_DAILY)
    {
        $sth = $dbh->prepare(qq|select distinct ar.id, ar.name, aaa.lastupdate 
                                       from artist ar, album al, album_amazon_asin aaa  
                                 where aaa.album = al.id and al.artist = ar.id 
                                 order by aaa.lastupdate asc, ar.id|);
    }
    elsif ($mode == MODE_ALL)
    {
    	$sth = $dbh->prepare(qq|select ar.id, ar.name from artist ar|);
    }
    else
    {
        die "Invalid Mode.\n";
    }

    $sth->execute();

    if ($sth->rows)
    {
        my @row;

		my $max = undef;
		$max = $limit if defined $limit;
		$max = $sth->rows * $percent / 100 if defined $percent;
		printf "%s : Will stop after %d artist%s\n",
			scalar(localtime), $max, ($max==1 ? "" : "s"),
			if defined $max;

        while(@row = $sth->fetchrow_array())
        {
            next if ($row[0] == &ModDefs::VARTIST_ID);
            next if ($mode == MODE_UPDATE && $row[2] > 0);

			my ($ret, $error);
            for(;;)
            {
            	my $t0 = [gettimeofday];
            	
                ($ret, $error) = MatchArtist($dbh, $row[1], $row[0]);
                
                # This is to prevent sending more than 1 query per second to Amazon, as per their TOS
                my $t1 = [gettimeofday];
                my $dur = (1.0 -  tv_interval($t0, $t1)) * 1000000;
                usleep($dur) unless $dur < 0;
                
                if ($ret == 0 && $error eq '')
                {
                    next if ($row[1] =~ s/\sand\s/ & /i);
                }
                last;
            }
            if ($error)
            {
                print localtime() . " : Error: $error\n"
					if $verbose;
            }
            if (defined $max)
            {
                --$max;
                last if $max <= 0;
            }
        }
    }
    $sth->finish;
}

sub ProcessSingleArtists
{
	my ($dbh, $artists) = @_;

	warn "Warning: no artists specified\n" if not @$artists;

	for my $artist (@$artists)
	{
		my $ar = Artist->new($dbh);

		if ($artist =~ /^(\d+)$/)
		{
			$ar->SetId($1);
			$ar->LoadFromId
				or warn("No artist #$1 found\n"), next;
		} else {
			$ar->LoadFromName($artist)
				or warn("No artist '$artist' found\n"), next;
		}

		my ($ret, $error) = MatchArtist($dbh, $ar->GetName, $ar->GetId);
		print "ret=$ret error=$error\n";
	}
}

sub Usage
{
   die <<EOF;
Usage: Match.pl [options]

Match MusicBrainz albums with Amazon albums and store ASINS and cover art URLs
in the database.

Options are:
  -v, --[no]verbose    [Don't] describe each artist processed (default: true
                       if at a terminal).  Use multiple times for more verbosity.
      --[no]summary    [Don't] show a summary on exit (default: true if at a
                       terminal)
      --debugfd=N      Log extra debugging info to file description N
  -h, --help           This help page

Select which artists to process:
  -f, --find           Match artists who have at least one "unknown" album
  -u, --update         Match only artists who have no Amazon matches at all
  -d, --daily          Match 1/30th of the artists that have the oldest asin
                       pairings
  -a, --all            Match all artists.  This can take a LONG time!
      --various        Include Various Artists albums in the search
  -s, --single         Match only the artist(s) given by "--artist"
      --artist=ARTIST  Specify artist IDs or names for --single to process

Select how many of those artists to process:
      --percentage=N   Match this percentage of applicable artists
      --limit=N        Stop after processing this many artists

Default is to process the whole selected dataset, or 3.3% if in "--daily" mode.

EOF
}

my $debugfd;
my @artist;

GetOptions(
	"verbose|v+"	=> \$verbose,
	"noverbose"		=> sub { undef $verbose },
	"summary!"		=> \$summary,
	"find|f"		=> sub { $mode = MODE_FIND },
	"update|u"		=> sub { $mode = MODE_UPDATE },
	"daily|d"		=> sub { $mode = MODE_DAILY },
	"all|a"			=> sub { $mode = MODE_ALL },
	"single|s"		=> sub { $mode = MODE_SINGLE },
	"various"		=> \$various,
	"artist=s"		=> \@artist,
	"debugfd=i"		=> \$debugfd,
	"percentage=f"	=> sub {
		die "--percentage out of range (must be >0, <=100)\n"
			if $_[1] <= 0 or $_[1] > 100;
		$percent = $_[1];
		$limit = undef;
	},
	"limit=i"		=> sub {
		$percent = undef;
		$limit = $_[1];
	},
	"help|h"		=> \&Usage,
) or exit 2;
Usage() if @ARGV;

$percent = 3.3 if $mode == MODE_DAILY
	and not defined $percent and not defined $limit;

warn "Warning: --artist ignored in this mode\n"
	if @artist and $mode != MODE_SINGLE;

# To debug requests and responses: e.g. --debug=3 3>debug.log
open(DEBUG, ">/dev/fd/$debugfd") if $debugfd;
open(DEBUG, ">/dev/null") unless $debugfd;

$| = 1;
my $mb = MusicBrainz->new;
$mb->Login;

print localtime() . " : Amazon match script starting\n";
eval 'END { print localtime() . " : Amazon match script ended\n" }';

# For debugging: specify "--single --artist='Foo Fighters' --artist=510 ..."

if ($mode == MODE_SINGLE)
{
	ProcessSingleArtists($mb->{DBH}, \@artist);
} else {
	MatchAlbums($mb->{DBH}, $mode, $percent, $limit); 
}

if ($summary)
{
	my $end_time = time;
	printf "%s : Artists processed: %d; VA Albums processed: %d; queries sent: %d; time taken: %d sec\n",
		scalar(localtime),
		$artists_processed,
		$va_processed,
		$queries_sent,
		$end_time - $start_time,
		;
}

# eof Match.pl
