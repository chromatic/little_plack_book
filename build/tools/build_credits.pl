#!/usr/bin/perl

use Modern::Perl;
use autodie;

open my $fh, '<:utf8', 'CREDITS';
my @names;

while (<$fh>)
{
    next unless /^N: (.+)$/;
    next if $1 eq 'chromatic';
    push @names, $1;
}

binmode STDOUT, ':utf8';
say "$_, " for
    map  { local $" = ' '; "@$_" }
    sort { $a->[-1] cmp $b->[-1] }
    map  { [ (split / /, $_) ] }
    @names;
