#!/usr/bin/perl
use strict;
use warnings;

my $imgDir = '/home/user/MyDocs/.images';

my %sets = (
  zelda => [map {"$imgDir/$_"} qw(
    zelda1.jpg zelda2.jpg zelda3.jpg
  )],
  menrva => [map {"$imgDir/$_"} qw(
    menrva.jpg jamaicad_drinks.jpg jamaicadyer_woman.jpg simnuke_cello.jpg
  )],
);

if(@ARGV == 0){
  die "Usage: $0 IMG IMG IMG ... " .
    "\nOR\n       $0 [" . join('|', keys %sets) . "]\n";
}

my $maybeSet = $ARGV[0];

my @desktops;
if(defined $sets{$maybeSet}){
  @desktops = @{$sets{$maybeSet}};
}else{
  @desktops = @ARGV;
}

my $size = @desktops;
print "Number of desktops: $size\n";
print "Background images: \n";
for(my $i=0; $i<@desktops; $i++){
  my $image = $desktops[$i];
  $image = " {leave alone}" if(not defined $image or not $image);
  print "  $i: $image\n";
}
my $list = '[';
for(my $i=0; $i<$size; $i++){
  $list .= $i+1;
  $list .= ',' if $i != $size-1;
}
$list .= ']';
system "gconftool-2 -s " .
  "/apps/osso/hildon-desktop/views/active " .
  "-t list --list-type int $list";
 
for(my $i=0; $i<$size; $i++){
  my $d = $i + 1;
  my $image = $desktops[$i];
  if(defined $image and $image){
    # ' => '\''  (end quote, literal quote, start quote)
    $image =~ s/'/'\\''/g;
    system "gconftool-2 -s " .
      "/apps/osso/hildon-desktop/views/$d/bg-image " .
      "-t string '$image'";
  }
}

