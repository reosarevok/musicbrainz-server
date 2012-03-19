package MusicBrainz::Server::Report::ReleasesInCAAWithCoverArtRelationships;
use Moose;

extends 'MusicBrainz::Server::Report::ReleaseReport';

sub gather_data
{
    my ($self, $writer) = @_;

    $self->gather_data_from_query($writer, "
        SELECT
            DISTINCT r.gid, rn.name, r.artist_credit AS artist_credit_id,
            musicbrainz_collate(an.name), musicbrainz_collate(rn.name)
        FROM
            release r
            JOIN artist_credit ac ON r.artist_credit = ac.id
            JOIN artist_name an ON ac.name = an.id
            JOIN release_name rn ON r.name = rn.id
            JOIN l_release_url lru ON entity0 = r.id
            JOIN link l ON l.id = lru.link
            JOIN link_type lt ON lt.id = l.link_type
            JOIN cover_art_archive.cover_art ON cover_art.release = r.id
        WHERE
            lt.gid = '2476be45-3090-43b3-a948-a8f972b4065c'
        ORDER BY musicbrainz_collate(an.name), musicbrainz_collate(rn.name)
    ");
}

sub template
{
    return 'report/releases_in_caa_with_cover_art_relationships.tt';
}

__PACKAGE__->meta->make_immutable;
no Moose;
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
