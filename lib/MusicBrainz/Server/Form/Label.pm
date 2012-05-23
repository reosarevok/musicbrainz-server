package MusicBrainz::Server::Form::Label;
use HTML::FormHandler::Moose;
extends 'MusicBrainz::Server::Form';

with 'MusicBrainz::Server::Form::Role::Edit';
with 'MusicBrainz::Server::Form::Role::DatePeriod';
with 'MusicBrainz::Server::Form::Role::CheckDuplicates';
with 'MusicBrainz::Server::Form::Role::IPI';

has '+name' => ( default => 'edit-label' );

has_field 'name' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
    required => 1,
);

has_field 'sort_name' => (
    type => '+MusicBrainz::Server::Form::Field::Text',
    required => 1,
);

has_field 'type_id' => (
    type => 'Select',
);

has_field 'label_code' => (
    type => '+MusicBrainz::Server::Form::Field::LabelCode',
    size => 5,
);

has_field 'country_id' => (
    type => 'Select',
);

has_field 'comment' => (
    type      => '+MusicBrainz::Server::Form::Field::Text',
    maxlength => 255
);

sub edit_field_names
{
    return qw( name sort_name comment type_id country_id
               begin_date end_date label_code ipi_codes ended );
}

sub options_type_id    { shift->_select_all('LabelType') }
sub options_country_id { shift->_select_all('Country') }

sub dupe_model { shift->ctx->model('Label') }

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
