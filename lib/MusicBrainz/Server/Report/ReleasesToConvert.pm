package MusicBrainz::Server::Report::ReleasesToConvert;
use Moose;

with 'MusicBrainz::Server::Report::ReleaseReport';

sub table { 'releases_to_convert' }

sub query {
    "
        SELECT DISTINCT release.id AS release_id,
          row_number() OVER (ORDER BY musicbrainz_collate(release_name.name))
        FROM track_name
        JOIN track ON track.name = track_name.id
        JOIN tracklist ON track.tracklist = tracklist.id
        JOIN medium ON medium.tracklist = tracklist.id
        JOIN release ON medium.release = release.id
        JOIN release_name ON release.name = release_name.id
        WHERE track_name.name ~* E'[^\\d]-[^\\d]' OR track_name.name LIKE '%/%'
        GROUP BY release.id, release_name.name, tracklist.id
        HAVING count(*) = tracklist.track_count
    ";
}

sub template
{
    return 'report/releases_to_convert.tt';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2010 MetaBrainz Foundation
Copyright (C) 2012 MetaBrainz Foundation

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
