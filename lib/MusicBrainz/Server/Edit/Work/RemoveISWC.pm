package MusicBrainz::Server::Edit::Work::RemoveISWC;
use Moose;
use MooseX::Types::Moose qw( Int Str );
use MooseX::Types::Structured qw( Dict );
use MusicBrainz::Server::Constants qw( $EDIT_WORK_REMOVE_ISWC );
use MusicBrainz::Server::Constants qw( :expire_action :quality );
use MusicBrainz::Server::Translation qw( l ln );

use aliased 'MusicBrainz::Server::Entity::Work';
use aliased 'MusicBrainz::Server::Entity::ISRC';

extends 'MusicBrainz::Server::Edit';
with 'MusicBrainz::Server::Edit::Work::RelatedEntities';
with 'MusicBrainz::Server::Edit::Work';

sub edit_name { l('Remove ISWC') }
sub edit_type { $EDIT_WORK_REMOVE_ISWC }

sub edit_conditions
{
    return {
        $QUALITY_LOW => {
            duration      => 4,
            votes         => 1,
            expire_action => $EXPIRE_ACCEPT,
            auto_edit     => 0,
        },
        $QUALITY_NORMAL => {
            duration      => 14,
            votes         => 3,
            expire_action => $EXPIRE_ACCEPT,
            auto_edit     => 0,
        },
        $QUALITY_HIGH => {
            duration      => 14,
            votes         => 4,
            expire_action => $EXPIRE_REJECT,
            auto_edit     => 0,
        },
    };
}

sub work_id { shift->data->{work}{id} }

has '+data' => (
    isa => Dict[
        iswc => Dict[
            id   => Int,
            iswc => Str
        ],
        work => Dict[
            id   => Int,
            name => Str
        ]
    ]
);

sub alter_edit_pending {
    my ($self) = @_;
    return {
        Work => [ $self->data->{work}{id} ],
        ISWC => [ $self->data->{iswc}{id} ]
    }
}

sub foreign_keys {
    my ($self) = @_;
    return {
        ISWC => [ $self->data->{iswc}{id} ],
        Work => { $self->data->{work}{id} => [ 'ArtistCredit'] }
    }
}

sub build_display_data {
    my ($self, $loaded) = @_;

    my $iswc = $loaded->{ISWC}{ $self->data->{iswc}{id} } ||
        ISWC->new( iswc => $self->data->{iswc}{iswc} );

    my $work = $loaded->{Work}{ $self->data->{work}{id} } ||
        Work->new( name => $self->data->{work}{name} );

    $iswc->work($work);

    return { iswc => $iswc };
}

sub initialize {
    my ($self, %opts) = @_;

    my $iswc = $opts{iswc} or die "Required 'iswc' object missing";
    $self->c->model('Work')->load($iswc) unless defined $iswc->work;
    $self->data({
        iswc => {
            id   => $iswc->id,
            iswc => $iswc->iswc,
        },
        work => {
            id   => $iswc->work->id,
            name => $iswc->work->name
        }
    });
}

sub accept {
    my $self = shift;
    $self->c->model('ISWC')->delete( $self->data->{iswc}{id} );
}

no Moose;
__PACKAGE__->meta->make_immutable;
