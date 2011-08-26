#!/usr/bin/perl
use strict;
use warnings;

sub add_hildon_shortcuts(\@){
  my @new = @{scalar shift};
  my $key = '/apps/osso/hildon-home/task-shortcuts';
  my $shct = `ssh root@\`n900\` gconftool-2 -g $key`;
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
  system "ssh root@`n900` gconftool-2 --set " .
    "--type list --list-type string $key $shct";
}

sub set_applets(\@\@\@){
  my @keydirs = @{scalar shift};
  my @views = @{scalar shift};
  my @positions = @{scalar shift};

  my $gconfcmd = "gconftool-2 --set ";
  
  my $cmd = "ssh root@`n900` '";
  for(my $i=0; $i<@keydirs; $i++){
    my $keydir = $keydirs[$i];
    my $view = $views[$i];
    my $position = $positions[$i];
    $cmd .=
      "$gconfcmd $keydir/modified -t string `date +%s`;" .
      "$gconfcmd $keydir/position -t list --list-type int $position;" .
      "$gconfcmd $keydir/view -t integer $view;" .
      "";
  }
  $cmd .= "'";

  if(@keydirs > 0){
    system $cmd;
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

sub get_contact_uids(){
  system "scp root@`n900`:/home/user/.osso-abook/db/addressbook.db .";
  open FH, "< addressbook.db";
  my @lines = <FH>;
  close FH;
  system "rm addressbook.db";

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

sub config_contacts(){

  print "configuring contact desktop shortcuts\n";

  #valid number is 7 or 10 digits
  #  number,  view, x-pos, y-pos
  my @contacts = (
    '6318975047', 1, 656, 56,
  );
  my %uid_by_num = %{get_contact_uids()};

  my $applets;
  my (@keydirs, @views, @positions);
  for(my $i=0; $i<@contacts; $i+=4){
    my $num = $contacts[$i];
    my $view = $contacts[$i+1];
    my $x = $contacts[$i+2];
    my $y = $contacts[$i+3];

    print "adding #$num to view $view at ($x,$y)\n";

    my $uid = $uid_by_num{$num};
    my $applet = "osso-abook-applet-$uid";
    $applets .= $applet;
    if($i+4 < @contacts){
      $applets .= ',';
    }

    my $keydir = "/apps/osso/hildon-desktop/applets/$applet";
    push @keydirs, $keydir;
    push @views, $view;
    push @positions, "[$x,$y]";
  }
  $applets = "[$applets]";

  my $key = '/apps/osso-addressbook/home-applets';
  system "ssh root@`n900` '" .
    "gconftool-2 -s -t list --list-type string $key $applets; " .
    "'";
 
  set_applets(@keydirs, @views, @positions);
}

sub config_desktop_cmd_exec(){
  print "\n\n\n";
  print "configuring desktop_cmd_exec and other widgets\n";

  my $other_widgets = '
[system_info.desktop-0]
X-Desktop-File=/usr/share/applications/hildon-home/system_info.desktop
';

  my $version = '0.7';
  my @cmds = (
    'cpu_fast'     => 'CPU\\nfast'    => 'udo cpu set 500 1000|echo',
    'cpu_slow'     => 'CPU\\nslow'    => 'udo cpu set 250 600|echo',
    'cpu_current'  => 'CPU cur freq'  => 'udo cpu get cur',
    'cpu_min'      => 'CPU min freq'  => 'udo cpu get min',
    'cpu_max'      => 'CPU max freq'  => 'udo cpu get max',
    'quick_ip'     => 'quick ip'      => 'udo quick_ip',
    'test_sms'     => 'test sms'      => 'udo send_sms 6314184821 test',
    'cpu_reset'    => 'reset'         => 'udo cpu set|echo',
    'locator'      => 'Locator'       => 'udo desktop_cmd_exec_locator',
    
    'uptime'       => 'Uptime:'       => 'uptime|cut -d" " -f4-|sed \'s/\\\\, *load.*//\'',
    'battery'      => 'Battery(%):'   => 'hal-device bme | awk -F"[. ]" \'$5 == "is_charging" {chrg = $7}\\;\\s$5 == "percentage" {perc = $7} END if (chrg == "false") {print perc "%"} else {print "Chrg"}\'',
    'battery_mah'  => 'Battery(mAh):' => 'hal-device bme | grep battery.reporting | awk -F. \'{print $3}\' | sort | awk \'$1 == "current" { current = $3}\\;\\s$1== "design" {print current "/" $3}\'',
    'boot_reason'  => 'Boot Reason:'  => 'cat /proc/bootreason',
    'boot_count'   => 'Boot Count:'   => 'cat /var/lib/dsme/boot_count',
    'external_ip'  => 'External IP:'  => 'wget --timeout=10 -q -O - api.myiptest.com | awk -F "\\\\"" \'{print $4}\'',
    'internal_ip'  => 'Internal IP:'  => '/sbin/ifconfig | grep "inet addr" | awk -F: \'{print $2}\' | awk \'{print $1}\'',
    'rootfs'       => 'rootfs:'       => 'df | awk \'$1 == "rootfs" {print $5}\'',
    'free_rootfs'  => 'Free Rootfs:'  => 'df -h | awk \' $1 == "rootfs" {print $4"B"}\'',
  );

  my @instances = (
    #title, width, height, display-title =>
    #update: click, desktop, boot, delay (index), network policy (index)
    #desktop/view widget should be on, and (x,y) coords
    #
    # title        width  ht  disp =>    updates     => desktop (x, y)
    'cpu_fast',    '.10',  '2.5', 1 => 1, 0, 0, 0, 0, => 1, 0,   56+76*0,
    'cpu_slow',    '.10',  '2.5', 1 => 1, 0, 0, 0, 0, => 1, 0,   56+76*1,
    'cpu_current', '.10',  '2.5', 0 => 1, 1, 1, 1, 0, => 1, 0,   56+76*2,
    'cpu_min',     '.10',  '2.5', 0 => 1, 1, 1, 1, 0, => 1, 0,   56+76*3,
    'cpu_max',     '.10',  '2.5', 0 => 1, 1, 1, 1, 0, => 1, 0,   56+76*4,
    'cpu_reset',   '.10',  '1.3', 1 => 1, 1, 1, 3, 0, => 1, 0,   56+76*5,
    'rootfs',      '.21',  '1.3', 1 => 1, 1, 1, 1, 0, => 1, 632, 404,
    'quick_ip',    '.21',  '1.3', 0 => 1, 0, 0, 3, 0, => 1, 632, 440,
    'test_sms',    '.14',  '1.3', 1 => 1, 0, 0, 0, 0, => 2, 688, 440,
  );
  
  my $size = int((@instances)/12);

  my $file = "
[config]
version=$version
";

  my (@titles, @commands, %titles_by_id, %commands_by_id);
  for(my $i=0; $i<@cmds; $i+=3){
    my $id = $cmds[$i];
    my $title = $cmds[$i+1];
    my $cmd = $cmds[$i+2];

    push @titles, $title;
    push @commands, $cmd;
    $titles_by_id{$id} = $title;
    $commands_by_id{$id} = $cmd;
  }
  $file .= 'c_titles=' . (join ';', @titles) . ";\n";
  $file .= 'c_commands=' . (join ';', @commands) . ";\n";

  my (@keydirs, @views, @positions);
  for(my $i=0; $i<@instances; $i+=12){
    my $id = $instances[$i];
    my $width = $instances[$i+1];
    my $height = $instances[$i+2];
    my $display_title = $instances[$i+3] ? 'true' : 'false';
    my $update_on_click = $instances[$i+4] ? 'true' : 'false';
    my $update_on_desktop = $instances[$i+5] ? 'true' : 'false';
    my $update_on_boot = $instances[$i+6] ? 'true' : 'false';
    my $update_delay_index = $instances[$i+7];
    my $update_network_policy = $instances[$i+8];

    my $view = $instances[$i+9];
    my $x = $instances[$i+10];
    my $y = $instances[$i+11];

    my $title = $titles_by_id{$id};
    my $cmd = $commands_by_id{$id};
    $cmd =~ s/\\;\\s/; /g;

    my $num = int($i/12);

    print "parsing instance " . ($num+1) . "/$size - $title {$id}\n";

    #its updNeworkPolicy [sic], with a typo missing a t
    $file .= "
[desktop-cmd-exec.desktop-$num]
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
    $keydir .= "desktop-cmd-exec.desktop-$num";
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
  system "scp .desktop_cmd_exec root@`n900`:/home/user";
  system "ssh root@`n900` chown user.users " .
    "/home/user/.desktop_cmd_exec";

  print "assembling new home.plugins list of hildon-desktop widgets\n";
  my $config = '/home/user/.config/hildon-desktop/home.plugins';
  open FH, '> home.plugins';
  print FH $other_widgets;
  for(my $j=0; $j<$size; $j++){
    print FH "[desktop-cmd-exec.desktop-$j]\n";
    print FH "X-Desktop-File=" .
      "/usr/share/applications/hildon-home/desktop-cmd-exec.desktop\n";
    print FH "\n";
  }
  close FH;

  print "copying home.plugins to tmp file on the n900\n";
  system "scp home.plugins root@`n900`:$config.tmp";
  print "clearing the current home.plugins\n";
  system "ssh root@`n900` 'echo > $config'";

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
  system "ssh root@`n900` mv $config.tmp $config";
  system "ssh root@`n900` chown user.users $config";
}

# use undef or '' to leave the image thats already present
my @desktops = (
  '/home/user/MyDocs/.images/menrva.jpg',
  '/home/user/MyDocs/.images/jamaicad_drinks.jpg',
  '/home/user/MyDocs/.images/jamaicadyer_woman.jpg',
  '/home/user/MyDocs/.images/simnuke_cello.jpg',
);

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
system "ssh root@`n900` gconftool-2 -s " .
  "/apps/osso/hildon-desktop/views/active " .
  "-t list --list-type int $list";
 
for(my $i=0; $i<$size; $i++){
  my $d = $i + 1;
  my $image = $desktops[$i];
  if(defined $image and $image){
    # ' => '\''  (end quote, literal quote, start quote)
    $image =~ s/'/\\'\\\\\\'\\'/g;
    system "ssh root@`n900` gconftool-2 -s " .
      "/apps/osso/hildon-desktop/views/$d/bg-image " .
      "-t string \\'$image\\'";
  }
}

print "\n\n\n";

print "clearing desktop (shortcuts, widgets, " .
  "bookmarks, contact-shortcuts)\n";
my $applets_key = '/apps/osso/hildon-desktop/applets';
my $shct_key = '/apps/osso/hildon-home/task-shortcuts';
my $bkmk_key = '/apps/osso/hildon-home/bookmark-shortcuts';
my $contacts_key = '/apps/osso-addressbook/home-applets';
system "ssh root@`n900` '" .
  "gconftool-2 --recursive-unset $applets_key; " . 
  "gconftool-2 -s -t list --list-type string $shct_key []; " .
  "gconftool-2 -s -t list --list-type string $bkmk_key []; " .
  "gconftool-2 -s -t list --list-type string $contacts_key []; " .
  "echo > /home/user/.config/hildon-desktop/home.plugins; " .
  "'";
    
config_contacts;

config_desktop_cmd_exec();

my @keydirs =
  ('/apps/osso/hildon-desktop/applets/system_info.desktop-0');
my @views = (1);
my @positions = ("[633,344]");
set_applets(@keydirs, @views, @positions);

my @elems;

@elems = (
   'alchemy', 'alchemy-dominion', 'fennec', 
   'prosperity', 'prosperity-dominion', 'mobilehotspot',
   'dominion', 'osso-xterm', 'pidgin',
   'hildon-control-panel', 'osso_calculator', 'FBReader',
);
desktop_grid('shortcut', 2, 3, 0, 56, 108, 108, @elems);

@elems = (
   'rtcom-call-ui', 'osso-addressbook', 'rtcom-messaging-ui',
);
desktop_grid('shortcut', 2, 1, 704, 56, 108, 108, @elems);

print "\n\n";
print "pkill hildon-desktop (auto-restarts with new positions)? [y/N] ";
my $response = <STDIN>;
chomp $response;
if(lc $response eq 'y'){
  system "ssh root@`n900` pkill hildon-desktop";
}else{
  print "skipped\n";
}

