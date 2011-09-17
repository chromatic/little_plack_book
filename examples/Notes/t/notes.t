#!/usr/bin/env perl

use Modern::Perl;

use Cwd;
use Dancer ();
use File::Temp;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

exit main();

sub main
{
    my $app = get_app();

    for my $test (qw( root index read create store ))
    {
        next unless my $sub = __PACKAGE__->can( 'test_' . $test );
        test_psgi $app, $sub;
    }

    done_testing();

    return 0;
}

sub get_app
{
    local $ENV{PLACK_ENV}           = 1;
    local $ENV{DANCER_APPDIR}       = cwd();
    Dancer::config()->{session_dir} = File::Temp::tempdir( CLEANUP => 1 );

    exit unless use_ok 'Notes';
    return Notes->dance;
}

sub test_root
{
    my $cb  = shift;
    my $res = $cb->( GET '/' );

    exit unless like $res->content, qr/<h1>Notes/, '/ should show index page';
    like $res->content, qr!/create">create new note</a>!,
        '... with link to create more notes';

    unlike $res->content, qr!/read/.+?">!, '... but no links to notes (yet)';
}

sub test_index
{
    my $cb  = shift;
    my $res = $cb->( GET '/index' );

    like $res->content, qr/<h1>Notes/, '/index should show index page';
    like $res->content, qr!/create">create new note</a>!,
        '... with link to create more notes';

    unlike $res->content, qr!/read/.+?">!, '... but no links to notes (yet)';
}

sub test_read
{
    my $cb  = shift;
    my $res = $cb->( GET '/read' );

    ok ! $res->is_success, '/read without option should give error';
    is $res->status_line, '404 Not Found', '... 404 in specific';

    $res    = $cb->( GET '/read/Empty' );
    ok $res->is_success, '/read/<title> should succeed, even given new note';

    my $content = $res->content;

    like $content, qr!<h1>Empty!, '... with note page';
    like $content, qr!This note is empty. Fill it in\?!,
        '... and empty note notice';

    like $content, qr!action="/store/Empty!,
        '... with form to fill in content';
    like $content, qr!<textarea[^>]+?>\s*</textarea>!s,
        '... but no content in empty content area';
}

sub test_create
{
    my $cb  = shift;
    my $res = $cb->( GET '/create' );

    ok $res->is_success, '/create should succeed without argument';

    my $content = $res->content;
    like $content, qr!action="/store"!, '... and should contain store form';
    like $content, qr!<input type="submit" value="Create" />!,
        '... and Create button';

    $res = $cb->( GET '/create?note=Some+Note' );
    ok $res->is_success, '/create should succeed given param';
    $content = $res->content;

    like $content, qr!<h1>Creating New Note</h1>!, '... returning create page';
    like $content, qr!name="note" value="Some Note"!,
        '... and populating note field with provided value';
    like $content, qr!name="contents"></textarea>!,
        '... but leaving contents field blank unless provided';

    $res = $cb->( GET '/create?note=Other+Note;contents=This+is+my+content' );
    ok $res->is_success, '/create should succeed given both params';
    $content = $res->content;

    like $content, qr!<h1>Creating New Note</h1>!, '... returning create page';
    like $content, qr!name="note" value="Other Note"!,
        '... populating note field with provided value';
    like $content, qr!name="contents">This is my content</textarea>!,
        '... and contents field when provided';

    $res = $cb->( GET '/create?contents=This+is+only+content' );
    ok $res->is_success, '/create should succeed given only one param';
    $content = $res->content;

    like $content, qr!<h1>Creating New Note</h1>!, '... returning create page';
    like $content, qr!name="contents">This is only content</textarea>!,
        '... populating contents field when provided';
    like $content, qr!name="note" value=""!,
        '... but not note field without value';
}

sub test_store
{
    my $cb  = shift;
    my $res = $cb->( POST '/store/Blah', [ contents => 'Blah blah blah' ] );
    ok $res->is_success, '/store/<id> with POSTed contents should succeed';

    $res = $cb->( POST '/store' );
    exit unless ok $res->is_success, '/store without option should succeed';

    $res = $cb->( POST '/store/Blah' );
    ok $res->is_success, '/store/<id> should succeed';
}
