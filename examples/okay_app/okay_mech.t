#!/usr/bin/env perl

use Modern::Perl;

use utf8;
use open ':encoding(utf8)';

use Test::More;
use Test::WWW::Mechanize::PSGI;
use Plack::Request;

my $app = sub
{
    my $res  = Plack::Request->new( shift );

    my $want = $res->param( 'want' );
    my $have = $res->param( 'have' );
    my $desc = $res->param( 'desc' );

    my ($code, $output) = ( $want eq $have )
                        ? ( 200, 'ok'      )
                        : ( 412, 'not ok'  );

    $output .= ' - ' . $desc if $desc;
    return [ $code, [ 'Content-Type' => 'text/plain' ], [ $output ] ];
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );
$mech->get_ok( '/?have=foo;want=foo',
    'Request should succeed when values match' );
$mech->content_is( 'ok', '... with descriptive success message' );

$mech->get( '/?have=10;want=20' );
ok ! $mech->success, 'Request should fail when values do not match';

$mech->content_is( 'not ok', '... with descriptive error' );

my $uri = URI->new( '/' );
$uri->query_form( have => 'cow', want => 'cow', desc => 'Cow Comparison' );
$mech->get_ok( $uri, 'Request should succeed when values do' );
$mech->content_is( 'ok - Cow Comparison',
    '... including description when provided' );
is $mech->content_type, 'text/plain', '... with plain text content';
is $mech->response->content_charset, 'US-ASCII', '... in ASCII';

$mech->post( '/', [ have => 'cow', want => 'pig', desc => 'æ' ] );
ok ! $mech->success, 'Request should fail given different values';
$mech->content_is( "not ok - \x{00E6}",
    '... including description when provided' );
is $mech->content_type, 'text/plain', '... with plain text content';
is $mech->response->content_charset, 'UTF-8', '... encoded as UTF-8';

done_testing();
