package MusicBrainz::Server::Report::FeaturingReleaseGroups;
use Moose;

extends 'MusicBrainz::Server::Report::ReleaseGroupReport';

sub gather_data
{
    my ($self, $writer) = @_;

    $self->gather_data_from_query($writer, "
        SELECT
            rg.gid AS release_group_gid, rn.name, rg.artist_credit AS artist_credit_id
        FROM
            release_group rg
            JOIN artist_credit ac ON rg.artist_credit = ac.id
            JOIN artist_name an ON ac.name = an.id
            JOIN release_name rn ON rg.name = rn.id
            JOIN release_group_meta rm ON rg.id = rm.id
        WHERE
            rn.name ~ E' \\\\(feat\\\\. '
        ORDER BY musicbrainz_collate(an.name), musicbrainz_collate(rn.name)
    ");
}

sub template
{
    return 'report/featuring_release_groups.tt';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2011 MetaBrainz Foundation

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
