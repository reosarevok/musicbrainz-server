package MusicBrainz::Server::Data::IPI;
use Moose;
use namespace::autoclean;

use Class::MOP;
use List::AllUtils qw( uniq );
use MusicBrainz::Server::Data::Utils qw(
    load_subobjects
    placeholders
    query_to_list
    object_to_ids
);

extends 'MusicBrainz::Server::Data::Entity';

has [qw( table type entity )] => (
    isa      => 'Str',
    is       => 'rw',
    # required => 1     # FIXME: should be required.
);

sub _table { shift->type . "_ipi" }
sub _columns { shift->type . ", ipi" }

sub _column_mapping
{
    my $self = shift;
    return {
        ipi                  => 'ipi',
        $self->type . '_id' => $self->type,
        edits_pending       => 'edits_pending',
    };
}

sub _entity_class
{
    return shift->entity;
}

sub find_by_entity_id
{
    my ($self, @ids) = @_;
    return [] unless @ids;

    my $key = $self->type;

    my $query = "SELECT " . $self->_columns . "
                 FROM " . $self->_table . "
                 WHERE $key IN (" . placeholders(@ids) . ")
                 ORDER BY ipi";

    return [ query_to_list($self->c->sql, sub {
        $self->_new_from_row(@_)
    }, $query, @ids) ];
}

sub load_for
{
    my ($self, @objects) = @_;
    my %obj_id_map = object_to_ids(@objects);
    my $ipis = $self->find_by_entity_id(keys %obj_id_map);
    my $id_column = $self->type . '_id';

    for my $ipi (@$ipis) {
        if (my $entities = $obj_id_map{ $ipi->$id_column }) {
            for my $entity (@$entities) {
                $entity->add_ipi_code($ipi);
            }
        }
    }

    return $ipis;
}

sub delete_entities
{
    my ($self, @entities) = @_;

    my $query = "DELETE FROM " . $self->table .
                " WHERE ".$self->type." IN (" . placeholders(@entities) . ")";
    $self->sql->do($query, @entities);
    return 1;
}

sub merge
{
    my ($self, $new_id, @old_ids) = @_;
    my $table = $self->table;
    my $type = $self->type;

    for my $old_id (@old_ids)
    {
        # move over ipis to the new artist, leaving duplicates.
        $self->sql->do("UPDATE $table SET $type = ? WHERE $type = ? ".
                       "AND NOT ipi IN (SELECT ipi FROM $table WHERE $type = ?)",
                       $new_id, $old_id, $new_id);
        # if any remain, they're duplicates, remove them.
        $self->sql->do("DELETE FROM $table WHERE $type = ?", $old_id);
    }
}

sub set_ipis {
    my ($self, $entity_id, @ipis) = @_;
    @ipis = uniq @ipis;
    my $table = $self->table;
    my $type = $self->type;

    $self->sql->do("DELETE FROM $table WHERE $type = ?", $entity_id);
    $self->sql->do(
        "INSERT INTO $table ($type, ipi) VALUES " .
            join(', ', ("(?, ?)") x @ipis),
        map { $entity_id, $_ } @ipis
    ) if @ipis;
}

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
