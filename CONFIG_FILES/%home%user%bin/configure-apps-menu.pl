#!/usr/bin/perl
use strict;
use warnings;

my @menu = qw(
rtcom-call-ui rtcom-messaging-ui osso-addressbook fmms xterm
browser pidgin claws-mail klomp image-viewer
worldclock mobilehotspot nokia-maps cavestory hildon-control-panel

evince FBReader fennec osso_calculator osso_sketch
osso-backup fapn gconf-editor maemoblocks chess_startup
mahjong_startup osso_lmarbles ines drnoksnes transmission
);

my $file = '/etc/xdg/menus/hildon.menu';

my $filenames = '';
for my $m(@menu){
  $filenames .= "    <Filename>$m.desktop</Filename>\n";
}
chomp $filenames;

my $content=
"<!DOCTYPE Menu PUBLIC \"-//freedesktop//DTD Menu 1.0//EN\"
 \"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd\">

<Menu>
  <Name>Main</Name>
  <AppDir>/usr/share/applications/hildon</AppDir>

  <Include>
$filenames
  </Include>

  <Layout>
$filenames
  </Layout>
</Menu>
";

my @others = `ls /usr/share/applications/hildon`;
print "Missing: \n";
my %present = map {$_ => 1} @menu;
for my $other(sort @others){
  $other =~ s/\.desktop$//;
  chomp $other;
  if(not defined $present{$other}){
    print "  $other\n";
  }
}

system "rm -f /home/user/.config/menus/hildon.menu";

open FH, "> $file" or die "Couldnt open file $file\n";
print FH $content;
close FH;
