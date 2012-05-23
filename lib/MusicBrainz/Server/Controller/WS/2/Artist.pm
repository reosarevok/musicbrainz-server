package MusicBrainz::Server::Controller::WS::2::Artist;
use Moose;
BEGIN { extends 'MusicBrainz::Server::ControllerBase::WS::2' }

use aliased 'MusicBrainz::Server::WebService::WebServiceStash';
use Readonly;

my $ws_defs = Data::OptList::mkopt([
     artist => {
                         method   => 'GET',
                         required => [ qw(query) ],
                         optional => [ qw(limit offset) ],
     },
     artist => {
                         method   => 'GET',
                         linked   => [ qw(recording release release-group work) ],
                         inc      => [ qw(aliases
                                          _relations tags user-tags ratings user-ratings) ],
                         optional => [ qw(limit offset) ]
     },
     artist => {
                         method   => 'GET',
                         inc      => [ qw(recordings releases release-groups works
                                          aliases various-artists
                                          _relations tags user-tags ratings user-ratings) ],
     },
]);

with 'MusicBrainz::Server::WebService::Validator' =>
{
     defs => $ws_defs,
};

with 'MusicBrainz::Server::Controller::Role::Load' => {
    model => 'Artist'
};

Readonly our $MAX_ITEMS => 25;

sub base : Chained('root') PathPart('artist') CaptureArgs(0) { }

sub artist : Chained('load') PathPart('')
{
    my ($self, $c) = @_;
    my $artist = $c->stash->{entity};

    my $stash = WebServiceStash->new;
    my $opts = $stash->store ($artist);

    $self->artist_toplevel ($c, $stash, $artist);

    $c->res->content_type($c->stash->{serializer}->mime_type . '; charset=utf-8');
    $c->res->body($c->stash->{serializer}->serialize('artist', $artist, $c->stash->{inc}, $stash));
}

sub artist_toplevel
{
    my ($self, $c, $stash, $artist) = @_;

    my $opts = $stash->store ($artist);

    $self->linked_artists ($c, $stash, [ $artist ]);

    $c->model('ArtistType')->load($artist);
    $c->model('Gender')->load($artist);
    $c->model('Country')->load($artist);
    $c->model('Artist')->ipi->load_for($artist);

    if ($c->stash->{inc}->recordings)
    {
        my @results = $c->model('Recording')->find_by_artist($artist->id, $MAX_ITEMS);
        $opts->{recordings} = $self->make_list (@results);

        $self->linked_recordings ($c, $stash, $opts->{recordings}->{items});
    }

    if ($c->stash->{inc}->releases)
    {
        my @results;
        if ($c->stash->{inc}->various_artists)
        {
            @results = $c->model('Release')->find_for_various_artists(
                $artist->id, $MAX_ITEMS, 0, filter => { status => $c->stash->{status}, type => $c->stash->{type}});
        }
        else
        {
            @results = $c->model('Release')->find_by_artist(
                $artist->id, $MAX_ITEMS, 0, filter => { status => $c->stash->{status}, type => $c->stash->{type}});
        }

        $opts->{releases} = $self->make_list (@results);

        $self->linked_releases ($c, $stash, $opts->{releases}->{items});
    }

    if ($c->stash->{inc}->release_groups)
    {
        my @results = $c->model('ReleaseGroup')->find_by_artist(
            $artist->id, $MAX_ITEMS, 0, filter => { type => $c->stash->{type} });
        $opts->{release_groups} = $self->make_list (@results);

        $self->linked_release_groups ($c, $stash, $opts->{release_groups}->{items});
    }

    if ($c->stash->{inc}->works)
    {
        my @results = $c->model('Work')->find_by_artist($artist->id, $MAX_ITEMS);
        $opts->{works} = $self->make_list (@results);

        $self->linked_works ($c, $stash, $opts->{works}->{items});
    }

    if ($c->stash->{inc}->has_rels)
    {
        my $types = $c->stash->{inc}->get_rel_types();
        my @rels = $c->model('Relationship')->load_subset($types, $artist);
    }
}

sub artist_browse : Private
{
    my ($self, $c) = @_;

    my ($resource, $id) = @{ $c->stash->{linked} };
    my ($limit, $offset) = $self->_limit_and_offset ($c);

    if (!MusicBrainz::Server::Validation::IsGUID($id))
    {
        $c->stash->{error} = "Invalid mbid.";
        $c->detach('bad_req');
    }

    my $artists;
    my $total;
    if ($resource eq 'recording')
    {
        my $recording = $c->model('Recording')->get_by_gid($id);
        $c->detach('not_found') unless ($recording);

        my @tmp = $c->model('Artist')->find_by_recording ($recording->id, $limit, $offset);
        $artists = $self->make_list (@tmp, $offset);
    }
    elsif ($resource eq 'release')
    {
        my $release = $c->model('Release')->get_by_gid($id);
        $c->detach('not_found') unless ($release);

        my @tmp = $c->model('Artist')->find_by_release ($release->id, $limit, $offset);
        $artists = $self->make_list (@tmp, $offset);
    }
    elsif ($resource eq 'release-group')
    {
        my $rg = $c->model('ReleaseGroup')->get_by_gid($id);
        $c->detach('not_found') unless ($rg);

        my @tmp = $c->model('Artist')->find_by_release_group ($rg->id, $limit, $offset);
        $artists = $self->make_list (@tmp, $offset);
    }
    elsif ($resource eq 'work')
    {
        my $work = $c->model('Work')->get_by_gid($id);
        $c->detach('not_found') unless ($work);

        my @tmp = $c->model('Artist')->find_by_work ($work->id, $limit, $offset);
        $artists = $self->make_list (@tmp, $offset);
    }

    my $stash = WebServiceStash->new;

    for (@{ $artists->{items} })
    {
        $self->artist_toplevel ($c, $stash, $_);
    }

    $c->res->content_type($c->stash->{serializer}->mime_type . '; charset=utf-8');
    $c->res->body($c->stash->{serializer}->serialize('artist-list', $artists, $c->stash->{inc}, $stash));
}

sub artist_search : Chained('root') PathPart('artist') Args(0)
{
    my ($self, $c) = @_;

    $c->detach('artist_browse') if ($c->stash->{linked});
    $self->_search ($c, 'artist');
}

__PACKAGE__->meta->make_immutable;
1;
