package MusicBrainz::Server::Form::Release::ReorderCoverArt;

use HTML::FormHandler::Moose;
extends 'MusicBrainz::Server::Form';
with 'MusicBrainz::Server::Form::Role::Edit';

has '+name' => ( default => 'reorder-cover-art' );

has_field 'artwork' => ( type => 'Repeatable' );
has_field 'artwork.id' => ( type => '+MusicBrainz::Server::Form::Field::Integer' );
has_field 'artwork.position' => ( type => '+MusicBrainz::Server::Form::Field::Integer' );

sub edit_field_names { qw( artwork ) }

no Moose;
__PACKAGE__->meta->make_immutable;


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
