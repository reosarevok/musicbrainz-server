package t::MusicBrainz::Server::Controller::Relationship::LinkAttributeType::Create;
use Test::Routine;
use Test::More;
use MusicBrainz::Server::Test qw( capture_edits html_ok );

around run_test => sub {
    my ($orig, $test, @args) = @_;
    $test->c->sql->do(<<'EOSQL');
INSERT INTO editor (id, name, password, email, privs)
  VALUES (1, 'editor1', 'pass', 'editor1@example.com', 255)
EOSQL

    $test->mech->get('/login');
    $test->mech->submit_form( with_fields => { username => 'editor1', password => 'pass' } );

    $test->$orig(@args);
};

with 't::Mechanize', 't::Context';

test 'Can create new relationship attribute' => sub {
    my $test = shift;
    my $mech = $test->mech;

    $mech->get_ok('/relationship-attributes/create');

    my ($name, $child_order) = (
        'Additional additional', 1
    );

    my @edits = capture_edits {
        my $response = $mech->submit_form(
            with_fields => {
                'linkattrtype.name' => $name,
                'linkattrtype.child_order' => $child_order
            }
        );
        ok($mech->success);
    } $test->c;

    is(@edits, 1);
    isa_ok($edits[0], 'MusicBrainz::Server::Edit::Relationship::AddLinkAttribute');
    is($edits[0]->data->{name}, $name, "Sets the name to $name");
    is($edits[0]->data->{child_order}, $child_order,
       "Sets the child order to $child_order");
};

test 'Can create child relationship attribute using parentid' => sub {
    my $test = shift;
    my $mech = $test->mech;
    my $gid = 'f6100277-c7b8-4c8d-aa26-d8cd014b6761';

    $test->c->sql->do(<<'EOSQL');
INSERT INTO link_attribute_type (id, root, gid, name)
  VALUES (1, 1, 'f6100277-c7b8-4c8d-aa26-d8cd014b6761', 'Trombone');
EOSQL

    $mech->get_ok('/relationship-attributes/create?parent=' . $gid);

    my $parent = $test->c->model('LinkAttributeType')->get_by_gid($gid);
    my ($parent_id, $parent_name, $name, $child_order) = (
        $parent->id, $parent->name, '77th trombone', 1
    );

    my @edits = capture_edits {
        my $response = $mech->submit_form(
            with_fields => {
                'linkattrtype.name' => $name,
                'linkattrtype.child_order' => $child_order
            }
        );
        ok($mech->success);
    } $test->c;

    is(@edits, 1);
    isa_ok($edits[0], 'MusicBrainz::Server::Edit::Relationship::AddLinkAttribute');
    is($edits[0]->data->{parent_id}, $parent_id, "Sets the parent to $parent_name");
    is($edits[0]->data->{name}, $name, "Sets the name to $name");
    is($edits[0]->data->{child_order}, $child_order,
       "Sets the child order to $child_order");
};

1;
