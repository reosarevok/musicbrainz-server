package MusicBrainz::Server::Translation::Scripts;
use Moose;
use namespace::autoclean;
BEGIN { extends 'MusicBrainz::Server::Translation'; }

with 'MusicBrainz::Server::Role::Translation' => { domain => 'scripts' };

sub l { __PACKAGE__->instance->gettext(@_) }
sub lp { __PACKAGE__->instance->pgettext(@_) }
sub ln { __PACKAGE__->instance->ngettext(@_) }

1;
