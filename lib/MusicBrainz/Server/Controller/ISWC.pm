package MusicBrainz::Server::Controller::ISWC;
use Moose;

use MusicBrainz::Server::Constants qw( $EDIT_WORK_REMOVE_ISWC );
use MusicBrainz::Server::Validation qw( is_valid_iswc );

BEGIN { extends 'MusicBrainz::Server::Controller'; }

with 'MusicBrainz::Server::Controller::Role::Load' => {
    model => 'ISWC',
};

sub base : Chained('/') PathPart('iswc') CaptureArgs(0) { }

sub _load : Chained('/') PathPart('iswc') CaptureArgs(1)
{
    my ($self, $c, $iswc) = @_;
    return unless (is_valid_iswc($iswc));

    my @iswcs = $c->model('ISWC')->find_by_iswc($iswc)
        or return;

    $c->stash(
        iswcs => \@iswcs,
        iswc => $iswc,
    );
}

sub show : Chained('load') PathPart('')
{
    my ($self, $c) = @_;

    my $iswcs = $c->stash->{iswcs};
    my @works = $c->model('Work')->load(@$iswcs);
    $c->model('WorkType')->load(@works);
    $c->model('Work')->load_writers(@works);
    $c->model('Work')->load_recording_artists(@works);
    $c->stash(
        works => \@works,
        template => 'iswc/index.tt',
    );
}

sub delete : Local Edit {
    my ($self, $c) = @_;

    my $iswc_id = $c->req->query_params->{iswc_id};
    my $iswc = $c->model('ISWC')->get_by_id($iswc_id);

    $c->model('Work')->load($iswc);
    $c->stash( iswc => $iswc );

    if (!$iswc) {
        $c->detach('/error_500');
        $c->stash( message => l('This ISWC does not exist' ));
    }

    $self->edit_action($c,
        form        => 'Confirm',
        edit_args   => { iswc => $iswc },
        type        => $EDIT_WORK_REMOVE_ISWC,
        on_creation => sub {
            $c->response->redirect($c->uri_for_action('/iswc/show', [ $iswc->iswc ]));
            $c->detach;
        }
    );
}

1;

=head1 COPYRIGHT

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
