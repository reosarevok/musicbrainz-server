package MusicBrainz::Server::Data::Language;

use Moose;
use namespace::autoclean;
use MusicBrainz::Server::Entity::Language;

use MusicBrainz::Server::Data::Utils qw( load_subobjects );

extends 'MusicBrainz::Server::Data::Entity';
with 'MusicBrainz::Server::Data::Role::EntityCache' => { prefix => 'lng' };
with 'MusicBrainz::Server::Data::Role::SelectAll' => { order_by => [ 'name'] };

sub _table
{
    return 'language';
}

sub _columns
{
    return 'id, iso_code_3, iso_code_2t, iso_code_2b, ' .
           'iso_code_1, name, frequency';
}

sub _entity_class
{
    return 'MusicBrainz::Server::Entity::Language';
}

sub load
{
    my ($self, @objs) = @_;
    load_subobjects($self, 'language', @objs);
}

sub find_by_code
{
    my ($self, $code) = @_;
    return $self->_get_by_key('iso_code_3' => $code, transform => 'lower');
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky

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
