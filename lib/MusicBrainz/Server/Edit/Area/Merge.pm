package MusicBrainz::Server::Edit::Area::Merge;
use Moose;

use MusicBrainz::Server::Constants qw( $EDIT_AREA_MERGE );
use MusicBrainz::Server::Translation qw( N_l );

extends 'MusicBrainz::Server::Edit::Generic::Merge';
with 'MusicBrainz::Server::Edit::Area';

sub edit_type { $EDIT_AREA_MERGE }
sub edit_name { N_l('Merge areas') }

sub _merge_model { 'Area' }

sub foreign_keys
{
    my $self = shift;
    return {
        Area => {
            map {
                $_ => [ 'AreaType' ]
            } (
                $self->data->{new_entity}{id},
                map { $_->{id} } @{ $self->data->{old_entities} },
            )
        }
    }
}

sub edit_template { 'MergeAreas' };

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 MetaBrainz Foundation

This file is part of MusicBrainz, the open internet music database,
and is licensed under the GPL version 2, or (at your option) any
later version: http://www.gnu.org/licenses/gpl-2.0.txt

=cut
