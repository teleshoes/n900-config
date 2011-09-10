#!/usr/bin/perl
use strict;
use warnings;

my $bgDir = '/home/user/images/backgrounds';

my %sets = (
  zelda => [qw(
    zelda1.jpg zelda2.jpg zelda3.jpg
  )],
  menrva => [qw(
    menrva.jpg jamaicad_drinks.jpg jamaicad_woman.jpg simnuke_cello.jpg
  )],
);

if(@ARGV == 0){
  die "Usage: $0 IMG IMG IMG ... " .
    "\nOR\n       $0 [" . join('|', keys %sets) . "]\n";
}

my @desktops;
if(@ARGV == 1 and defined $sets{$ARGV[0]}){
  @desktops = @{$sets{$ARGV[0]}};
}else{
  @desktops = @ARGV;
}

for my $desktop(@desktops){
  if(not -e $desktop and -e "$bgDir/$desktop"){
    $desktop = "$bgDir/$desktop";
  }
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

