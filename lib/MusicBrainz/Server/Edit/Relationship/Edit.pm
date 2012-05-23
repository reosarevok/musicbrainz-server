package MusicBrainz::Server::Edit::Relationship::Edit;
use Moose;
use Carp;
use Clone 'clone';
use Moose::Util::TypeConstraints qw( as subtype find_type_constraint );
use MooseX::Types::Moose qw( ArrayRef Bool Int Str );
use MooseX::Types::Structured qw( Dict Optional );
use MusicBrainz::Server::Constants qw( $EDIT_RELATIONSHIP_EDIT );
use MusicBrainz::Server::Edit::Exceptions;
use MusicBrainz::Server::Entity::Types;
use MusicBrainz::Server::Edit::Types qw( PartialDateHash Nullable );
use MusicBrainz::Server::Data::Utils qw(
  partial_date_to_hash
  partial_date_from_row
  type_to_model
);
use MusicBrainz::Server::Translation qw( l ln );

use aliased 'MusicBrainz::Server::Entity::Link';
use aliased 'MusicBrainz::Server::Entity::LinkType';
use aliased 'MusicBrainz::Server::Entity::Relationship';

extends 'MusicBrainz::Server::Edit::WithDifferences';
with 'MusicBrainz::Server::Edit::Relationship';
with 'MusicBrainz::Server::Edit::Relationship::RelatedEntities';

sub edit_type { $EDIT_RELATIONSHIP_EDIT }
sub edit_name { l("Edit relationship") }

sub _xml_arguments { ForceArray => ['attributes'] }

subtype 'LinkHash'
    => as Dict[
        link_type => Dict[
            id => Int,
            name => Str,
            link_phrase => Str,
            reverse_link_phrase => Str,
            short_link_phrase => Str
        ],
        attributes => Nullable[ArrayRef[Int]],
        begin_date => Nullable[PartialDateHash],
        end_date => Nullable[PartialDateHash],
        ended => Optional[Bool],
        entity0 => Nullable[Dict[
            id => Int,
            name => Str,
        ]],
        entity1 => Nullable[Dict[
            id => Int,
            name => Str,
        ]]
    ];

subtype 'RelationshipHash'
    => as Dict[
        link_type => Nullable[Dict[
            id => Int,
            name => Str,
            link_phrase => Str,
            reverse_link_phrase => Str,
            short_link_phrase => Str
        ]],
        attributes => Nullable[ArrayRef[Int]],
        begin_date => Nullable[PartialDateHash],
        end_date => Nullable[PartialDateHash],
        ended => Optional[Bool],
        entity0 => Nullable[Dict[
            id => Int,
            name => Str,
        ]],
        entity1 => Nullable[Dict[
            id => Int,
            name => Str,
        ]]
    ];

has '+data' => (
    isa => Dict[
        relationship_id => Int,
        type0 => Str,
        type1 => Str,
        link => find_type_constraint('LinkHash'),
        new => find_type_constraint('RelationshipHash'),
        old => find_type_constraint('RelationshipHash'),
    ]
);

has 'relationship' => (
    isa => 'Relationship',
    is => 'rw'
);

sub foreign_keys
{
    my ($self) = @_;

    my $model0 = type_to_model($self->data->{type0});
    my $model1 = type_to_model($self->data->{type1});

    my %load;

    $load{LinkType} = [
        $self->data->{link}->{link_type}{id},
        $self->data->{new}{link_type} ? $self->data->{new}{link_type}{id} : (),
        $self->data->{old}{link_type} ? $self->data->{old}{link_type}{id} : (),
    ];
    $load{LinkAttributeType} = [
        @{ $self->data->{link}->{attributes} },
        @{ $self->data->{new}->{attributes} || [] },
        @{ $self->data->{old}->{attributes} || [] }
    ];

    my $old = $self->data->{old};
    my $new = $self->data->{new};

    $load{$model0} = {};
    $load{$model1} = {};

    $load{$model0}->{ $self->data->{link}->{entity0}{id} } = [ 'ArtistCredit' ];
    $load{$model1}->{ $self->data->{link}->{entity1}{id} } = [ 'ArtistCredit' ];
    $load{$model0}->{ $old->{entity0}{id} } = [ 'ArtistCredit' ] if $old->{entity0};
    $load{$model1}->{ $old->{entity1}{id} } = [ 'ArtistCredit' ] if $old->{entity1};
    $load{$model0}->{ $new->{entity0}{id} } = [ 'ArtistCredit' ] if $new->{entity0};
    $load{$model1}->{ $new->{entity1}{id} } = [ 'ArtistCredit' ] if $new->{entity1};

    return \%load;
}

sub _build_relationship
{
    my ($self, $loaded, $data, $change) = @_;

    my $link = $data->{link};
    my $model0 = type_to_model($data->{type0});
    my $model1 = type_to_model($data->{type1});

    my $begin      = defined $change->{begin_date}   ? $change->{begin_date}   : $link->{begin_date};
    my $end        = defined $change->{end_date}     ? $change->{end_date}     : $link->{end_date};
    my $ended      = defined $change->{ended}        ? $change->{ended}        : $link->{ended};
    my $attributes = defined $change->{attributes}   ? $change->{attributes}   : $link->{attributes};
    my $entity0    = defined $change->{entity0}      ? $change->{entity0}      : $link->{entity0};
    my $entity1    = defined $change->{entity1}      ? $change->{entity1}      : $link->{entity1};
    my $lt         = defined $change->{link_type}    ? $change->{link_type}    : $link->{link_type};

    return unless $entity0 && $entity1;

    return Relationship->new(
        link => Link->new(
            type       => $loaded->{LinkType}{ $lt->{id} } || LinkType->new( $lt ),
            begin_date => partial_date_from_row( $begin ),
            end_date   => partial_date_from_row( $end ),
            ended      => $ended,
            attributes => [
                map {
                    my $attr    = $loaded->{LinkAttributeType}{ $_ };
                    my $root_id = $self->c->model('LinkAttributeType')->find_root($attr->id);
                    $attr->root( $self->c->model('LinkAttributeType')->get_by_id($root_id) );
                    $attr;
                } @$attributes
            ]
        ),
        entity0 => $loaded->{$model0}{ $entity0->{id} } ||
            $self->c->model($model0)->_entity_class->new( name => $entity0->{name} ),
        entity1 => $loaded->{$model1}{ $entity1->{id} } ||
            $self->c->model($model1)->_entity_class->new( name => $entity1->{name} ),
    );
}

sub build_display_data
{
    my ($self, $loaded) = @_;

    my $old = $self->data->{old};
    my $new = $self->data->{new};

    return {
        old => $self->_build_relationship ($loaded, $self->data, $old),
        new => $self->_build_relationship ($loaded, $self->data, $new),
    };
}

sub directly_related_entities
{
    my ($self) = @_;

    my $old = $self->data->{old};
    my $new = $self->data->{new};

    my $type0 = $self->data->{type0};
    my $type1 = $self->data->{type1};

    my %result;
    $result{$type0} = [];
    $result{$type1} = [];

    push @{ $result{$type0} }, $old->{entity0}{id} if $old->{entity0};
    push @{ $result{$type0} }, $new->{entity0}{id} if $new->{entity0};
    push @{ $result{$type0} }, $self->data->{link}{entity0}{id};
    push @{ $result{$type1} }, $old->{entity1}{id} if $old->{entity1};
    push @{ $result{$type1} }, $new->{entity1}{id} if $new->{entity1};
    push @{ $result{$type1} }, $self->data->{link}{entity1}{id};

    return \%result;
}

sub adjust_edit_pending
{
    my ($self, $adjust) = @_;

    $self->c->model('Relationship')->adjust_edit_pending(
        $self->data->{type0}, $self->data->{type1},
        $adjust, $self->data->{relationship_id});
}

sub _mapping
{
    return (
        begin_date => sub { return partial_date_to_hash (shift->link->begin_date); },
        end_date =>   sub { return partial_date_to_hash (shift->link->end_date);   },
        ended => sub { return shift->link->ended },
        attributes => sub { return [ map { $_->id } shift->link->all_attributes ]; },
        link_type => sub {
            my $rel = shift;
            my $lt = $rel->link->type;
            return {
                id => $lt->id,
                name => $lt->name,
                link_phrase => $lt->link_phrase,
                reverse_link_phrase => $lt->reverse_link_phrase,
                short_link_phrase => $lt->short_link_phrase,
            };
        },
        entity0 => sub {
            my $rel = shift;
            return { id => $rel->entity0->id, name => $rel->entity0->name };
        },
        entity1 => sub {
            my $rel = shift;
            return { id => $rel->entity1->id, name => $rel->entity1->name };
        }
    );
}

sub initialize
{
    my ($self, %opts) = @_;

    my $relationship = delete $opts{relationship};
    my $type0 = delete $opts{type0};
    my $type1 = delete $opts{type1};

    unless ($relationship->entity0 && $relationship->entity1) {
        $self->c->model('Relationship')->load_entities($relationship);
    }

    $opts{entity0} = {
        id => $opts{entity0}->id,
        name => $opts{entity0}->name
    } if $opts{entity0};

    $opts{entity1} = {
        id => $opts{entity1}->id,
        name => $opts{entity1}->name
    } if $opts{entity1};

    $opts{link_type} = {
        id => $opts{link_type}->id,
        name => $opts{link_type}->name,
        link_phrase => $opts{link_type}->link_phrase,
        reverse_link_phrase => $opts{link_type}->reverse_link_phrase,
        short_link_phrase => $opts{link_type}->short_link_phrase
    } if $opts{link_type};

    my $link = $relationship->link;

    $self->relationship($relationship);
    $self->data({
        type0 => $type0,
        type1 => $type1,
        relationship_id => $relationship->id,
        link => {
            begin_date => partial_date_to_hash ($link->begin_date),
            end_date =>   partial_date_to_hash ($link->end_date),
            ended => $link->ended,
            attributes => [ map { $_->id } $link->all_attributes ],
            link_type => {
                id => $link->type_id,
                name => $link->type->name,
                link_phrase => $link->type->link_phrase,
                reverse_link_phrase => $link->type->reverse_link_phrase,
                short_link_phrase => $link->type->short_link_phrase
            },
            entity0 => {
                id => $relationship->entity0_id,
                name => $relationship->entity0->name
            },
            entity1 => {
                id => $relationship->entity1_id,
                name => $relationship->entity1->name
            },
        },
        $self->_change_data($relationship, %opts)
    });
}

sub accept
{
    my $self = shift;

    my $data = clone($self->data);

    my $relationship = $self->c->model('Relationship')->get_by_id(
        $data->{type0}, $data->{type1},
        $data->{relationship_id}
    );

    MusicBrainz::Server::Edit::Exceptions::FailedDependency->throw(
        'This relationship has already been deleted'
    ) if !$relationship;

    $self->c->model('Link')->load($relationship);

    # Because we're using a "find_or_insert" instead of an update, this link
    # dict should be complete.  If a value isn't defined in $values in doesn't
    # change, so take the original value as it was stored in $link.
    my $values = {
        entity0_id   => $data->{new}{entity0}{id}   // $relationship->entity0_id,
        entity1_id   => $data->{new}{entity1}{id}   // $relationship->entity1_id,
        attributes   => $data->{new}{attributes}    // [
            map { $_->id } $relationship->link->all_attributes
        ],
        link_type_id => $data->{new}{link_type}{id} // $relationship->link->type_id,
        begin_date   => $data->{new}{begin_date}    // $relationship->link->begin_date,
        end_date     => $data->{new}{end_date}      // $relationship->link->end_date,
        ended        => $data->{new}{ended}         // $relationship->link->ended
    };

    MusicBrainz::Server::Edit::Exceptions::FailedDependency->throw(
        'This relationship already exists'
    ) if $self->c->model('Relationship')->exists(
        $data->{type0},
        $data->{type1},
        $values
    );

    MusicBrainz::Server::Edit::Exceptions::FailedDependency->throw(
        'One of the end points of this relationship no longer exists'
    ) if !$self->c->model(type_to_model($data->{type0}))->get_by_id($values->{entity0_id}) ||
         !$self->c->model(type_to_model($data->{type1}))->get_by_id($values->{entity1_id});

    $self->c->model('Relationship')->update(
        $data->{type0},
        $data->{type1},
        $data->{relationship_id},
        $values
    );

    my $link_type = $self->c->model('LinkType')->get_by_id(
        $values->{link_type_id}
    );

    if ($self->c->model('CoverArt')->can_parse($link_type->name)) {
        my $relationship = $self->c->model('Relationship')->get_by_id(
            $data->{type0}, $data->{type1},
            $data->{relationship_id}
        );

        my $release = $self->c->model('Release')->get_by_id(
            $relationship->entity0_id
        );
        $self->c->model('Relationship')->load_subset([ 'url' ], $release);
        $self->c->model('CoverArt')->cache_cover_art($release);
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky
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
