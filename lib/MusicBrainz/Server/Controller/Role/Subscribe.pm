package MusicBrainz::Server::Controller::Role::Subscribe;
use Moose::Role -traits => 'MooseX::MethodAttributes::Role::Meta::Role';
use namespace::autoclean;

use List::MoreUtils qw( part );
use MusicBrainz::Server::Data::Utils qw( type_to_model );
use MusicBrainz::Server::Plugin::Canonicalize qw ( replace_gid );

sub subscribers : Chained('load') RequireAuth {
    my ($self, $c) = @_;

    my $model = $self->{model};
    my $entity = $c->stash->{ $self->{entity_name} };

    my @all_editors = $c->model($model)->subscription->find_subscribed_editors($entity->id);
    $c->model('Editor')->load_preferences(@all_editors);
    my ($public, $private) = part { $_->preferences->public_subscriptions ? 0 : 1 } @all_editors;

    $public ||= [];
    $private ||= [];

    my %props = (
        canonicalURL => MusicBrainz::Server::Plugin::Canonicalize::replace_gid($self, $c, $entity->gid),
        entity => $entity,
        privateEditors => scalar @$private,
        publicEditors => $public,
        subscribed => $c->model($model)->subscription->check_subscription($c->user->id, $entity->id),
    );

     $c->stash(
        component_path => $entity->entity_type . '/' . type_to_model($entity->entity_type) . 'Subscribers.js',
        component_props => \%props,
        current_view => 'Node',
    );

}

1;
