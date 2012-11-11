#!/usr/bin/perl
use strict;
use warnings;
use Safe;

##########################################
my $configFile = '/home/user/.desktop-config';
my $unsafeCode = `cat $configFile`;
my $compartment = new Safe;
my @config = $compartment->reval($unsafeCode);
if(@config != 6){
  die "Could not read config from $configFile\n";
}
print "Loaded profile from $configFile\n\n";

my @desktops = @{$config[0]};
my @contacts = @{$config[1]};
my @shortcutGrids = @{$config[2]};
my @applets = @{$config[3]};
my @dce_instances = @{$config[4]};
my @dce_cmds = @{$config[5]};
##########################################

sub runcmdget($){
  my $cmd = shift;
  return `$cmd`;
}
sub runcmd($){
  my $cmd = shift;
  system $cmd;
}

sub set_desktop_images(@);
sub clear_desktop();
sub config_contacts();
sub config_applets(@);
sub config_shortcuts(@);

sub get_contact_uids();
sub set_applets(\@\@\@);
sub desktop_grid($$$$$$$\@);
sub add_hildon_shortcuts(\@);
sub config_desktop_cmd_exec($);

sub main(@){
  set_desktop_images(@desktops);
  print "\n\n\n";

  clear_desktop();

  config_contacts();
  config_applets(@applets);
  config_shortcuts(@shortcutGrids);


  print "\n\n";
  my $restart = 0;

  if(@ARGV == 1 and $ARGV[0] eq '--restart'){
    $restart = 1;
  }else{
    print "pkill hildon-desktop (auto-restarts with new positions)? [y/N] ";
    my $response = <STDIN>;
    chomp $response;
    if(lc $response eq 'y'){
      $restart = 1;
    }else{
      print "skipped\n";
    }
  }

  if($restart){
    print "running pkill hildon-desktop\n";
    runcmd "pkill hildon-desktop";
  }
}

sub set_desktop_images(@){
  my @imgs = map {"'$_'"} @_;
  runcmd "pseudo set-desktop-images.pl @imgs";
}

sub clear_desktop(){
  print "clearing desktop (shortcuts, widgets, " .
    "bookmarks, contact-shortcuts)\n";
  my $applets_key = '/apps/osso/hildon-desktop/applets';
  my $shct_key = '/apps/osso/hildon-home/task-shortcuts';
  my $bkmk_key = '/apps/osso/hildon-home/bookmark-shortcuts';
  my $contacts_key = '/apps/osso-addressbook/home-applets';
  runcmd
    "gconftool-2 --recursive-unset $applets_key; " . 
    "gconftool-2 -s -t list --list-type string $shct_key []; " .
    "gconftool-2 -s -t list --list-type string $bkmk_key []; " .
    "gconftool-2 -s -t list --list-type string $contacts_key []; " .
    "echo > /home/user/.config/hildon-desktop/home.plugins";
}

sub config_contacts(){
  print "configuring contact desktop shortcuts\n";

  my %uid_by_num = %{get_contact_uids()};

  my $applets;
  my (@keydirs, @views, @positions);
  for(my $i=0; $i<@contacts; $i++){
    my $contact = $contacts[$i];
    my $num = $$contact[0];
    my $view = $$contact[1];
    my $x = $$contact[2];
    my $y = $$contact[3];

    print "adding #$num to view $view at ($x,$y)\n";

    my $uid = $uid_by_num{$num};
    my $applet = "osso-abook-applet-$uid";
    $applets .= $applet;
    if($i < $#contacts){
      $applets .= ',';
    }

    my $keydir = "/apps/osso/hildon-desktop/applets/$applet";
    push @keydirs, $keydir;
    push @views, $view;
    push @positions, "[$x,$y]";
  }
  $applets = "[$applets]";

  my $key = '/apps/osso-addressbook/home-applets';
  runcmd "gconftool-2 -s -t list --list-type string $key '$applets'";
 
  set_applets(@keydirs, @views, @positions);
}

sub config_applets(@){
  my $other_widgets;
  my %appIndexes;
  my @appletNames;
  my @views;
  my @positions;
  for my $applet(@_){
    my $view = $$applet[0];
    my $xPos = $$applet[1];
    my $yPos = $$applet[2];
    my $name = $$applet[3];
    my $gconfDir = $$applet[4];
    my $appDir = $$applet[5];
    if($name !~ /\.desktop$/){
      $name .= '.desktop';
    }
    my $index = 0;
    if(defined $appIndexes{"$gconfDir$name"}){
      $index = $appIndexes{"$gconfDir$name"} + 1;
    }
    $appIndexes{"$gconfDir$name"} = $index;

    push @appletNames, "$gconfDir$name-$index";
    push @views, $view;
    push @positions, "[$xPos,$yPos]";
    $other_widgets .= "[$name-$index]\nX-Desktop-File=$appDir$name\n\n";
  }
  config_desktop_cmd_exec($other_widgets);
  set_applets(@appletNames, @views, @positions);
}

sub config_shortcuts(@){
  for my $grid(@_){
    my $view = $$grid[0];
    my $rowSize = $$grid[1];
    my $leftPos = $$grid[2];
    my $topPos = $$grid[3];
    my $itemWidth = $$grid[4];
    my $itemHeight = $$grid[5];
    my @elems = @{$$grid[6]};

    desktop_grid('shortcut', $view, $rowSize, $leftPos, $topPos,
      $itemWidth, $itemHeight, @elems);
  }
}

#####
#####
#####

sub get_contact_uids(){
  open FH, "< /home/user/.osso-abook/db/addressbook.db";
  my @lines = <FH>;
  close FH;

  @lines = reverse @lines;
  my %uid_by_num;
  for(my $i=0; $i<@lines; $i++){
    if($lines[$i] =~ /^TEL.*1?(\d{3}?\d{7})/){
      my $num = $1;
      $i++;
      until($lines[$i] =~ /^UID:/){
        $i++;
      }
      $lines[$i] =~ /^UID:.*?(\d+)/;
      my $uid = $1;
      $uid_by_num{$num} = $uid;
    }
  }
  return \%uid_by_num;
}

sub set_applets(\@\@\@){
  my @keydirs = @{shift()};
  my @views = @{shift()};
  my @positions = @{shift()};

  my $gconfcmd = "gconftool-2 --set ";

  my $cmd = "";
  for(my $i=0; $i<@keydirs; $i++){
    my $keydir = $keydirs[$i];
    my $view = $views[$i];
    my $position = $positions[$i];
    $cmd .=
      "$gconfcmd $keydir/modified -t string `date +%s`; " .
      "$gconfcmd $keydir/position -t list --list-type int $position; " .
      "$gconfcmd $keydir/view -t integer $view; ";
  }

  if(length $cmd > 0){
    runcmd $cmd;
  }
}

sub desktop_grid($$$$$$$\@){
  my $type = shift;
  my $view = shift;
  my $row_size = shift;
  my $left = shift;
  my $top = shift;
  my $elem_width = shift;
  my $elem_height = shift;
  my @elems = @{scalar shift};

  print "\n\n\n";

  if($type eq 'shortcut'){
    print "The following are application shortcuts\n";
    print "Their gconf keys look like TaskShortcut:APPNAME.desktop\n";
  }elsif($type eq 'normal'){
    print "The following are the actual gconf keys to be set\n";
  }else{
    die "Unknown type '$type' in setting a desktop grid\n";
  }

  print "\nGrid will be on desktop $view (1st desktop is 1), " .
    "at ($left, $top)\n";
  my $max_len = 0;
  for my $e(@elems){
    my $len = length $e;
    $max_len = $len if $len > $max_len;
  }
  for(my $i=0; $i<@elems; $i++){
    my $e = $elems[$i];
    print "$e " . ' 'x($max_len - length $e);
    print "\n" if ($i+1) % $row_size == 0;
  }
  if($type eq 'shortcut'){
    add_hildon_shortcuts(@elems);
  }
  my (@keydirs, @views, @positions);
  for(my $i=0; $i<@elems; $i++){
    my $elem = $elems[$i];
    if($type eq 'shortcut'){
      $elem = "TaskShortcut:$elem.desktop";
    }
    my $keydir = "/apps/osso/hildon-desktop/applets/$elem";
    
    my $x = $i % $row_size;
    my $y = int($i / $row_size);
    my $x_pix = $left + $elem_width*$x;
    my $y_pix = $top + $elem_height*$y;
    my $position = "[$x_pix,$y_pix]";
    push @keydirs, $keydir;
    push @views, $view;
    push @positions, $position;
  }
  set_applets(@keydirs, @views, @positions);
}

sub add_hildon_shortcuts(\@){
  my @new = @{scalar shift};
  my $key = '/apps/osso/hildon-home/task-shortcuts';
  my $shct = runcmdget "gconftool-2 -g $key";
  chomp $shct;
  $shct =~ s/^\[(.*)\]$/$1/s;
  my @old = split ',', $shct;
  for my $new_shct(@new){
    $new_shct .= '.desktop';
    my $found = 0;
    for my $old_shct(@old){
      if($new_shct eq $old_shct){
        $found = 1;
        last;
      }
    }
    unless($found){
      push @old, $new_shct;
    }
  }

  $shct = '[' . (join ',', @old) . ']';
  runcmd "gconftool-2 --set --type list --list-type string $key '$shct'";
}

sub config_desktop_cmd_exec($){
  print "\n\n\n";
  print "configuring desktop_cmd_exec and other widgets\n";

  my $other_widgets = shift;
  my $version = '0.7';

  my @cmds = @dce_cmds;
  my @instances = @dce_instances;

  my $size = @instances;

  my $file = "
[config]
version=$version
";

  my (@titles, @commands, %titles_by_id, %commands_by_id);
  for my $cmd(@cmds){
    my $id = $$cmd[0];
    my $title = $$cmd[1];
    my $cmdExec = $$cmd[2];

    push @titles, $title;
    push @commands, $cmdExec;
    $titles_by_id{$id} = $title;
    $commands_by_id{$id} = $cmdExec;
  }
  $file .= 'c_titles=' . (join ';', @titles) . ";\n";
  $file .= 'c_commands=' . (join ';', @commands) . ";\n";

  my (@keydirs, @views, @positions);
  for(my $i=0; $i<@instances; $i++){
    my $instance = $instances[$i];
    my $id = $$instance[0];
    my $width = $$instance[1];
    my $height = $$instance[2];
    my $display_title = $$instance[3] ? 'true' : 'false';
    my $update_on_click = $$instance[4] ? 'true' : 'false';
    my $update_on_desktop = $$instance[5] ? 'true' : 'false';
    my $update_on_boot = $$instance[6] ? 'true' : 'false';
    my $update_delay_index = $$instance[7];
    my $update_network_policy = $$instance[8];

    my $view = $$instance[9];
    my $x = $$instance[10];
    my $y = $$instance[11];

    my $title = $titles_by_id{$id};
    my $cmd = $commands_by_id{$id};
    $cmd =~ s/\\;\\s/; /g;

    print "parsing instance " . ($i+1) . "/$size - $title {$id}\n";

    #its updNeworkPolicy [sic], with a typo missing a t
    $file .= "
[desktop-cmd-exec.desktop-$i]
widthRatio=0$width
heightRatio=$height
displayTitle=$display_title
updOnClick=$update_on_click
updOnDesktop=$update_on_desktop
updOnBoot=$update_on_boot
delayIndex=$update_delay_index
updNeworkPolicy=$update_network_policy
instanceTitle=$title
instanceCmd=$cmd
";
    my $keydir = "/apps/osso/hildon-desktop/applets/";
    $keydir .= "desktop-cmd-exec.desktop-$i";
    my $position = "[$x,$y]";
    push @keydirs, $keydir;
    push @views, $view;
    push @positions, $position;
  }
  print "sending instance applet positions..\n";
  set_applets(@keydirs, @views, @positions);

  open FH, '> .desktop_cmd_exec';
  print FH $file;
  close FH;

  print "copying newly generated .desktop_cmd_exec conf file\n";
  runcmd "cp .desktop_cmd_exec /home/user";
  runcmd "chown user.users /home/user/.desktop_cmd_exec";

  my $tmp = '/tmp/home.plugins';

  print "assembling new home.plugins list of hildon-desktop widgets\n";
  my $config = '/home/user/.config/hildon-desktop/home.plugins';
  open FH, '> /tmp/home.plugins';
  print FH $other_widgets;
  for(my $j=0; $j<$size; $j++){
    print FH "[desktop-cmd-exec.desktop-$j]\n";
    print FH "X-Desktop-File=" .
      "/usr/share/applications/hildon-home/desktop-cmd-exec.desktop\n";
    print FH "\n";
  }
  close FH;

  print "clearing the current home.plugins\n";
  runcmd "echo > $config";

  my $timeout = 5;
  print "waiting $timeout seconds: ";
  my $flush = $|;
  $| = 1;
  for(my $t=$timeout; $t>0; $t--){
    print "$t ";
    sleep 1;
  }
  $| = $flush;

  print "\nok, moving the file to .config/home.plugins\n";
  runcmd "mv $tmp $config";
  runcmd "chown user.users $config";
}

&main(@ARGV);
