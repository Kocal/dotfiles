#!/usr/bin/env perl
# Checks every ```text block of a release-announcement file against its platform limit.
# Usage: perl count.pl <file.md>    (exit 1 when a block is over its limit)

use strict;
use warnings;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';

my $file = shift or die "Usage: perl count.pl <file.md>\n";
open my $fh, '<:encoding(UTF-8)', $file or die "Cannot read $file: $!\n";
my @lines = <$fh>;
close $fh;

my $emoji = qr/\p{Extended_Pictographic}|[0-9#*]\x{FE0F}?\x{20E3}|[\x{1F1E6}-\x{1F1FF}]/;

# twitter-text: a URL weighs 23, an emoji 2, Latin and common punctuation 1, everything else 2.
sub x_weight {
    my ($text) = @_;
    my $weight = 0;
    $text =~ s{https?://\S+}{$weight += 23; ''}ge;
    for my $grapheme ($text =~ /(\X)/g) {
        if ($grapheme =~ /\A$emoji/) {
            $weight += 2;
            next;
        }
        my $cp = ord $grapheme;
        my $light = $cp <= 4351
            || ($cp >= 8192 && $cp <= 8205)
            || ($cp >= 8208 && $cp <= 8223)
            || ($cp >= 8242 && $cp <= 8247);
        $weight += $light ? 1 : 2;
    }
    return $weight;
}

sub graphemes {
    my ($text) = @_;
    my $count = () = $text =~ /\X/g;
    return $count;
}

my ($section, $heading, $in_block, @block) = ('', '', 0);
my $over = 0;

for my $line (@lines) {
    if (!$in_block && $line =~ /^##\s+(.*?)\s*$/ && $line !~ /^###/) {
        $section = $1;
    }
    if (!$in_block && $line =~ /^###\s+(.*?)\s*$/) {
        $heading = $1;
    }
    if (!$in_block && $line =~ /^```text\s*$/) {
        ($in_block, @block) = (1);
        next;
    }
    if ($in_block && $line =~ /^```\s*$/) {
        $in_block = 0;
        my $text = join '', @block;
        $text =~ s/\n\z//;
        my $label = $heading ne '' && $section !~ /linkedin/i ? "$section / $heading" : $section;

        if ($section =~ /linkedin/i) {
            my $n = graphemes($text);
            my $ok = $n <= 3000;
            $over ||= !$ok;
            printf "%-4s %s: LinkedIn %d/3000\n", ($ok ? 'OK' : 'OVER'), $label, $n;
        } else {
            my $x = x_weight($text);
            my $bsky = graphemes($text);
            my $ok = $x <= 280 && $bsky <= 300;
            $over ||= !$ok;
            printf "%-4s %s: X %d/280, Bluesky %d/300\n", ($ok ? 'OK' : 'OVER'), $label, $x, $bsky;
        }
        $heading = '';
        next;
    }
    push @block, $line if $in_block;
}

exit($over ? 1 : 0);
