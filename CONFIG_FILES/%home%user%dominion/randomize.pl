#!/usr/bin/perl
use strict;
use warnings;
use List::Util 'shuffle';

my $DIR = `dirname $0`;
chomp $DIR;
$DIR = `$DIR/abspath.py $DIR`;
chomp $DIR;

sub choose($$);
sub buildHTML(@);

my @always = qw(copper silver gold estate duchy province curse);
my %kingdoms;

sub main(\@){
  my $arg = shift;
  $arg = '' if not defined $arg;
  my (@top, @bottom);

  if($arg eq 'p'){
    my @kcards = choose 10, 'prosperity';
    @top = (@kcards[0..4], 'img/platinum.jpg');
    @bottom = (@kcards[5..9], 'img/colony.jpg');
  }elsif($arg eq 'a'){
    my @kcards = choose 10, 'alchemy';
    @top = (@kcards[0..4], 'img/potion.jpg');
    @bottom = @kcards[5..9];
  }elsif($arg eq 'd'){
    my @kcards = choose 10, 'dominion';
    @top = @kcards[0..4];
    @bottom = @kcards[5..9];
  }elsif($arg eq 'pd'){
    my @kcards = (choose(4, 'prosperity'), choose(6, 'dominion'));
    @top = (@kcards[0..4]);
    @bottom = (@kcards[5..9]);
    if(rand() * 10 < 4){
      push @top, 'img/platinum.jpg';
      push @bottom, 'img/colony.jpg';
    }
  }elsif($arg eq 'ad'){
    my @kcards = (choose(4, 'alchemy'), choose(6, 'dominion'));
    @top = (@kcards[0..4]);
    @bottom = (@kcards[5..9]);
  }
  $_ = "img/$_.jpg" for @always;
  print buildHTML [@top], [@bottom], [@always];
}

sub buildHTML(@){
  my $html = "<table>\n";
  for my $arr(@_){
    my @row = @{$arr};
    $html .= "  <tr>\n";
    $html .= "    <td><img width=\"160px\" src=\"file://$DIR/$_\"/></td>\n" for @row;
    $html .= "  </tr>\n";
  }
  $html .= "</table>\n";
  return $html;
}

sub choose($$){
  my $num = shift;
  my $kingdom = shift;
  my @arr = shuffle @{$kingdoms{$kingdom}};
  $num = $#arr if $num > $#arr;
  @arr = @arr[0..$num-1];
  $_ = "img/kingdom/$kingdom/$_.jpg" for @arr;
  return @arr;
}
my @kingdom_dirs = `ls $DIR/img/kingdom`;
for my $kingdom(@kingdom_dirs){
  chomp $kingdom;
  my @cards = `ls $DIR/img/kingdom/$kingdom`;
  s/.jpg\n?$// for @cards;
  $kingdoms{$kingdom} = \@cards;
}

&main(@ARGV);
