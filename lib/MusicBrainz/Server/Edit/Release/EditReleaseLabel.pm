package MusicBrainz::Server::Edit::Release::EditReleaseLabel;
use Moose;

use Moose::Util::TypeConstraints qw( find_type_constraint subtype as );
use MooseX::Types::Moose qw( Int Str );
use MooseX::Types::Structured qw( Dict );
use MusicBrainz::Server::Constants qw( $EDIT_RELEASE_EDITRELEASELABEL );
use MusicBrainz::Server::Edit::Exceptions;
use MusicBrainz::Server::Edit::Types qw( Nullable );
use MusicBrainz::Server::Translation qw( l ln );

extends 'MusicBrainz::Server::Edit::WithDifferences';
with 'MusicBrainz::Server::Edit::Role::Preview';
with 'MusicBrainz::Server::Edit::Release::RelatedEntities';
with 'MusicBrainz::Server::Edit::Release';

sub edit_name { l('Edit release label') }
sub edit_type { $EDIT_RELEASE_EDITRELEASELABEL }

sub alter_edit_pending { { Release => [ shift->release_id ] } }

use aliased 'MusicBrainz::Server::Entity::Label';
use aliased 'MusicBrainz::Server::Entity::Release';

subtype 'ReleaseLabelHash'
    => as Dict[
        label => Nullable[Dict[
            id => Int,
            name => Str,
        ]],
        catalog_number => Nullable[Str]
    ];

has '+data' => (
    isa => Dict[
        release_label_id => Int,
        release => Dict[
            id => Int,
            name => Str,
            date => Nullable[Str],
            country => Nullable[Str],
            barcode => Nullable[Str],
            combined_format => Nullable[Str],
        ],
        new => find_type_constraint('ReleaseLabelHash'),
        old => find_type_constraint('ReleaseLabelHash')
    ]
);

sub release_id { shift->data->{release}{id} }
sub release_label_id { shift->data->{release_label_id} }

sub foreign_keys
{
    my $self = shift;

    my $keys = { Release => { $self->release_id => [] } };

    $keys->{Label}->{ $self->data->{old}{label}{id} } = [] if $self->data->{old}{label};
    $keys->{Label}->{ $self->data->{new}{label}{id} } = [] if $self->data->{new}{label};

    return $keys;
};

sub build_display_data
{
    my ($self, $loaded) = @_;

    my $data = {
        release => $loaded->{Release}->{ $self->release_id },
        catalog_number => {
            new => $self->data->{new}{catalog_number},
            old => $self->data->{old}{catalog_number},
        },
        extra => $self->data->{release}
    };

    for (qw( new old )) {
        if (my $lbl = $self->data->{$_}{label}) {
            next unless %$lbl;
            $data->{label}{$_} = $loaded->{Label}{ $lbl->{id} } ||
                Label->new( name => $lbl->{name} );
        }
    }

    return $data;
}

around '_build_related_entities' => sub {
    my $orig = shift;
    my $self = shift;
    my $related = $self->$orig;

    $related->{label} = [
        $self->data->{new}{label} ? $self->data->{new}{label}{id} : (),
        $self->data->{old}{label} ? $self->data->{old}{label}{id} : (),
    ];

    return $related;
};

sub _mapping {
    my $self = shift;
    return (
        label => sub {
            my $rl = shift;
            return $rl->label ? {
                id => $rl->label->id,
                name => $rl->label->name
            } : undef;
        }
    )
}

sub initialize
{
    my ($self, %opts) = @_;
    my $release_label = delete $opts{release_label};
    die "You must specify the release label object to edit"
        unless defined $release_label;

    unless ($release_label->release) {
        $self->c->model ('Release')->load ($release_label);
        $self->c->model ('Country')->load ($release_label->release);
        $self->c->model ('Medium')->load_for_releases ($release_label->release);
        $self->c->model ('MediumFormat')->load ($release_label->release->all_mediums);
    }

    unless ($release_label->label) {
        $self->c->model('Label')->load($release_label);
    }

    if (my $lbl = $opts{label}) {
        $opts{label} = {
            id => $lbl->id,
            name => $lbl->name
        }
    }

    my $data = {
        release_label_id => $release_label->id,
        release => {
            id => $release_label->release->id,
            name => $release_label->release->name,
            combined_format => $release_label->release->combined_format_name,
        },
        $self->_change_data($release_label, %opts),
    };

    $data->{release}{date} = $release_label->release->date->format
        if $release_label->release->date;

    $data->{release}{country} = $release_label->release->country->name
        if $release_label->release->country;

    $data->{release}{barcode} = $release_label->release->barcode->format
        if $release_label->release->barcode;

    $data->{old}{catalog_number} = $release_label->catalog_number;
    $data->{old}{label} = $release_label->label ? {
        'name' => $release_label->label->name,
        'id' => $release_label->label->id
    } : undef;

    $self->data ($data);
};

sub accept
{
    my $self = shift;

    my %args;
    if (exists $self->data->{new}{label})
    {
        $args{label_id} = $self->data->{new}{label} ? $self->data->{new}{label}{id} : undef;
    }

    $args{catalog_number} = $self->data->{new}{catalog_number}
        if exists $self->data->{new}{catalog_number};

    if (my $label_id = $args{label_id}) {
        MusicBrainz::Server::Edit::Exceptions::FailedDependency->throw(
            'The new label no longer exists'
        ) unless $self->c->model('Label')->get_by_id($label_id);
    }

    $self->c->model('ReleaseLabel')->update($self->release_label_id, \%args);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2010 MetaBrainz Foundation

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
