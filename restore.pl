#!/usr/bin/perl
use strict;
use warnings;

#Bookmarks:
#A%defs%
#  the data structures that hold the util
#B%main%
#  the code that comprises the path of execution
#C%utils%
#  the actual configuration subs
#D%ui%
#  printing display, reading a command, and executing the right sub
#E%text%
#  large bodies of freetext

my $DIR = '/home/wolke/Desktop/N900/config';
chdir $DIR;

###############################
###############################
###############################
#A%defs%

#keyboard character -> subroutine name
my %keys;

#list of subroutines in the order described in the left column
my @order;

my @headers;
#each section contains an array of 3-element arrays
my @sections;

my @utils = (
#TOP
'header' => "N900 Utilities:",
  'xx' => 'q' => 'quit',
  'xx' => 'w' => 'print_restore_instructions',
  'xx' => 'e' => 'execute_all_in_order',
  'xx' => 'r' => 'license',
'header' => "",
'header' => "Routine Maintenance:",
  'xx' => 't' => 'retrieve_apt_cache',
  '17' => 'y' => 'sync_pidgin',
  'xx' => 'u' => 'backup_dcim',
  'xx' => 'i' => 'reorganize_dcim',
  'xx' => 'o' => 'backup',
#BOTTOM
'header' => "Install Packages:",
  '03' => '1' => 'apt_cache',
  '04' => '2' => 'apt_update',
  '05' => '4' => 'apt_install_crucial',
  '08' => '3' => 'apt_upgrade',
  '09' => '5' => 'apt_install_preferred',
  '10' => '6' => 'apt_unblock_ovi (apt)',
  '11' => '7' => 'apt_install_blocked_ovi',
  '12' => '8' => 'install_others',
'header' => "Copy Files/Settings:",
  '06' => 'a' => 'config_files',
  '07' => 's' => 'root_symlinks',
  '15' => 'd' => 'sync_mydocs',
  '18' => 'f' => 'default_cpu_limits',
  '19' => 'g' => 'xterm_color',
  '20' => 'h' => 'xterm_virtual_kb',
  '21' => 'j' => 'configure_desktop', 
  '22' => 'k' => 'add_music_symlinks', 
  '23' => 'l' => 'hosts',
  '24' => ';' => 'remember', 
'header' => "EMERGENCY RECOVERY:",
  '01' => 'z' => 'reflash',
  '02' => 'x' => 'ssh_setup',
  '13' => 'c' => 'format_mydocs_ext3',
  '14' => 'v' => 'reboot_phone',
  '16' => 'b' => 'restore_backup',
);

###############################
###############################
###############################
#B%main%

sub parse_utils();
sub ui_cmd_prompt();
sub handleCmd($);

sub ask($);
sub callMagicSub($);

sub get_license_text();
sub get_instructions_text();

parse_utils();

for my $arg(@ARGV){
  handleCmd $arg;
}

while(1){
  ui_cmd_prompt();
}
exit 0;

###############################
###############################
###############################
#C%utils%

sub quit(){
  exit 0;
}

sub print_restore_instructions($){
  my $novel = get_instructions_text();
  system "echo \"$novel\" | more";
}

sub execute_all_in_order(){
  my $len = length (1 + scalar @order);
  my $i=1;
  for my $sub(@order){
    print ' 'x($len-(length $i)).$i++." $sub\n";
  }

  print "\n\nExecuting the above, in the above order\n";
  print "Pressing enter without typing a response skips each step\n";
  for my $sub(@order){
    $sub =~ s/([0-9a-zA-Z_-]+).*/$1/sxi;
    callMagicSub $sub;
  }
}

sub license(){
  system "clear";
  print get_license_text();
}

sub retrieve_apt_cache(){
  if(ask 'sync n900:/var/cache/apt/ to apt-cache?'){
    system "rsync -av --del root@`n900`:/var/cache/apt/ " .
      "./packages/apt-cache";
  }
}

sub sync_pidgin(){
  if(ask 'sync pidgin logs?'){
    system "./utils/syncPidgin";
  }
}

sub backup_dcim(){
  if(ask 'rsync n900:DCIM to localhost:DCIM?'){
    system "rsync -av root@`n900`:/home/user/MyDocs/DCIM/ ../MyDocs/DCIM/";
  }
}

sub reorganize_dcim(){
  if(ask 'rsync n900:DCIM to localhost:DCIM?'){
    system "rsync -av root@`n900`:/home/user/MyDocs/DCIM/ ../MyDocs/DCIM/";
  }
  print "\n\n\nMAKE YOUR ### DIRECTORIES NOW.\n";
  print "DONT MOVE VIDEOS TO DCIM_VIDEOS, WE'LL DO THAT LATER\n\n\n";
  print "when youre done, this script will make the n900 match whatchoo did";
  if(ask 'mv dcim files around on n900 to match localhost?'){
    system "./utils/presync " .
      "../MyDocs/DCIM " .
      "root@`n900`:/home/user/MyDocs/DCIM";
  }
  if(ask 'make dcim video symlinks and rearrange on localhost?'){
    system "/home/wolke/bin/dcim_videos /home/wolke/Desktop/N900/MyDocs";
  }
  if(ask 'make dcim video symlinks and rearrange on n900?'){
    system "ssh root@`n900` /home/user/bin/dcim_videos /home/user/MyDocs";
  }
  if(ask 'rsync localhost:DCIM to N900:DCIM?'){
    system "rsync -av ../MyDocs/DCIM/ root@`n900`:/home/user/MyDocs/DCIM/";
  }
  if(ask 'rsync localhost:DCIM_VIDEOS to N900:DCIM_VIDEOS?'){
    system "rsync -av ../MyDocs/DCIM_VIDEOS/ " .
      "root@`n900`:/home/user/MyDocs/DCIM_VIDEOS/";
  }
  if(ask 'chown user.users N900:DCIM and N900:DCIM_VIDEOS'){
    system "ssh root@`n900` chown user.users -R /home/user/MyDocs/DCIM";
    system "ssh root@`n900` chown user.users -R /home/user/MyDocs/DCIM_VIDEOS";
  }
}

sub backup(){
  if(ask 'run backup, and sync it locally?'){
    system "ssh root@`n900` pseudo backup";
    system "rsync -av root@`n900`:/media/mmc1/Backup/Latest/ ../Backup/Latest";
  }
}


#####

sub apt_cache(){
  if(ask 'copy apt-cache?'){
    system "scp -r packages/apt-cache root@`n900`:/opt/var/cache/apt-new";
    system "ssh root@`n900` 'cd /opt/var/cache/; rm -rf apt; mv apt-new apt'";
  }
}

sub apt_update(){
  if(ask 'apt-get update?'){
    system "ssh root@`n900` apt-get update";
  }
}

sub apt_upgrade(){
  if(ask 'apt-get upgrade?'){
    system "ssh root@`n900` apt-get upgrade";
  }
}

sub apt_install_crucial(){
  my $crucial_packages =
   ' openssh kernel-power-settings bash vim' .
   ' diffutils-gnu findutils-gnu grep-gnu rsync wget' .
   ' coreutils-gnu tar-gnu python-location';
  print "\n\nCrucial packages:\n$crucial_packages";
  print "\n\n\n\n";
  print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  print "KERNEL POWER. ASKS YOU. TO CONTINUE. ON THE PHONE\n";
  print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
  if(ask 'install crucial packages (hit accept on the phone)?'){
    system "ssh root@`n900` apt-get install $crucial_packages";
  }
}

sub apt_install_preferred(){
  my $preferred_packages =
   ' mobilehotspot desktop-cmd-exec simple-brightness-applet fbreader' .
   ' fmms wifi-switcher pidgin fapn shortcutd systeminfowidget evince' .
   ' easy-deb-chroot openvpn ringtoned flashlight-applet' .
   ' pidgin-maemo-docklet personal-ip-address mplayer mediabox ' .
   ' gstreamer0.10-flac libflac8 perl-modules make unzip ping' .
   ' ines drnoksnes xmodmap ogg-support git-core' .
   ' nxengine';
  print "\n\nPreferred packages:\n$preferred_packages";
  if(ask 'apt-get update first?'){
    system "ssh root@`n900` apt-get update";
  }
  if(ask 'install preferred packages (hit accept on the phone)?'){
    system "ssh root@`n900` apt-get install $preferred_packages";
  }
}

sub apt_unblock_ovi(){
  if(ask 'remove mp-fremantle-002-pr and install old apt?'){
    system "scp ./packages/apt_*_armel.deb root@`n900`:/home/user";
    system "ssh root@`n900` apt-get remove mp-fremantle-002-pr";
    system "ssh root@`n900` dpkg -i /home/user/apt_*_armel.deb";
    system "ssh root@`n900` rm /home/user/apt_*_armel.deb";
  }
}

sub apt_install_blocked_ovi(){
  my $ovi_packages =
   'fennec';
  print "\n\nOvi packages:\n$ovi_packages";
  print "\nMAY HANG during install: will prompt for autofix";
  if(ask 'install packages blocked by ovi-store crippled apt?'){
    system "ssh root@`n900` apt-get install $ovi_packages";
    if(ask '  wanna pkill apt-get; dpkg --configure -a?'){
      system "ssh root@`n900` 'pkill apt-get; dpkg --configure -a'";
    }
  }
}

sub installDebsFromLocal(@){
  if(ask "install @_\n from locally stored debs {in ./packages}?"){
    for my $debFile(@_){
      my $realDeb = $debFile;
      $realDeb = `cd ./packages; ls $realDeb`;
      chomp $realDeb;
      $realDeb =~ s/'/'\\''/g;
      $realDeb = "'$realDeb'";
      print "installing $realDeb\n";
      system "scp ./packages/$realDeb root@`n900`:/opt";
      system "ssh root@`n900` dpkg -i /opt/$realDeb";
      system "ssh root@`n900` rm /opt/$realDeb";
    }
  }
}

sub install_others(){
  if(ask 'install klomp from github?'){
    my $d = '/home/user/klomp';
    my $url = 'git://github.com/teleshoes/klomp.git';

    system "ssh root@`n900` '" .
      "if [ -d $d ]; then " .
        "cd $d; git pull; " .
      "else " .
        "git clone $url $d; " .
      "fi" .
      "'";
  }
  if(ask 'install gcc-4.2 & g++-4.2 from SDK repo {disabled after}, and add links?'){
    system "ssh root@`n900` '" .
      "cd /etc/apt/sources.list.d; " .
      "mv sdk.list.disabled sdk.list; " .
      "apt-get update; " .
      "apt-get install gcc-4.2 g++-4.2; " .
      "mv sdk.list sdk.list.disabled; " .
      "apt-get update; " .
      "ln -s /usr/bin/gcc-4.2 /usr/bin/gcc; " .
      "ln -s /usr/bin/gcc-4.2 /usr/bin/cc; " .
      "ln -s /usr/bin/g++-4.2 /usr/bin/g++; " .
      "'";
  }

  installDebsFromLocal(
    "maemo-select-menu-location*.deb",
    "gconf-editor*.deb",
  );

  installDebsFromLocal("fcron_*_armel_opt.deb");
  if(ask 'setup fcron?'){
    system "ssh root@`n900` '".
      "useradd fcron; " .
      "chown root:fcron /etc/fcron.*; " .
      "chmod 644 /etc/fcron.*; " .
      "chown -R fcron:fcron /var/spool/fcron; " .
      "/etc/init.d/fcron start; " .
      "fcrontab /etc/fcrontab; " .
      "'";
  }

  installDebsFromLocal(
    "curl_*_armel.deb",
    "libcurl3_*_armel.deb",
    "libssl0.9.7_*_armel.deb",
  );

  installDebsFromLocal("unison_*_armel.deb");

  if(ask 'optify cpan?'){
    system "ssh root@`n900` '" .
      "cp -ar /root/.cpan /opt/.cpan; " .
      "rm -rf /root/.cpan; " .
      "mkdir -p /opt/.cpan; " .
      "ln -s /opt/.cpan /root/.cpan; " .
      "'";
  }

  if(ask 'cpan upgrade?'){
    my $cmd = "ssh root@`n900` 'cpan Bundle::CPAN; cpan -u'";
    system $cmd;
    if(ask '  if it failed, trying again might work. try again?'){
      system $cmd;
    }
  }

  if(ask 'install Term::ReadKey perl module through cpan?'){
    my $cmd = "ssh root@`n900` 'cpan Term::ReadKey'";
    system $cmd;
    if(ask '  if it failed, trying again might work. try again?'){
      system $cmd;
    }
  }

  if(ask 'install Net::Twitter perl module through cpan?'){
    my $cmd = "ssh root@`n900` 'cpan " .
      "Params::Validate DateTime::Locale DateTime " .
      "DateTime::Format::Strptime " .
      "Net::Twitter" .
      "'";
    system $cmd;
    if(ask '  if it failed, trying again might work. try again?'){
      system $cmd;
    }
  }
}


sub config_files(){
  if(ask 'Sync and override CONFIG_FILES?'){
    system "rsync -av --del ".
      "$DIR/CONFIG_FILES/ ".
      "root@`n900`:/opt/CONFIG_FILES";
    system "ssh root@`n900` /opt/CONFIG_FILES/config-overwrite.pl";
  }
}

sub root_symlinks(){
  if(ask 'add symlinks to .bashrc, etc. from /root/* => /home/user/ ?'){
    system './utils/root-user.pl';
  }
  if(ask 'add /root/bin/pseudo=>/bin/pseudo, etc?'){
    system "ssh root@`n900` '" .
      "rm /bin/udo; " .
      "rm /bin/pseudo; " .
      "ln -s /root/bin/udo /bin/udo; " .
      "ln -s /root/bin/pseudo /bin/pseudo; " .
      "'";
  }
  if(ask 'replace mobilehotspot.desktop symlink with copy?'){
    my $src = '/opt/mobilehotspot/resources/mobilehotspot.desktop';
    my $ln = '/usr/share/applications/hildon/mobilehotspot.desktop';
    system "ssh root@`n900` 'rm $ln; cp $src $ln'";
  }
  if(ask 'replace /usr/bin/stat with a symlink to gstat?'){
    system "ssh root@`n900` '" .
      "if [ -L /usr/bin/stat ]; then " .
        "rm /usr/bin/stat; " .
      "else " .
        "mv /usr/bin/stat /usr/bin/stat_busybox; " .
      "fi; " .
      "ln -s gstat /usr/bin/stat; " .
    "'";
  }
}

sub sync_mydocs(){
  if(ask 'sync mydocs (ignores files named DCIM* and debian*.img.ext2)?'){
    system "rsync -av " .
     "../MyDocs/ " .
     "root@`n900`:/home/user/MyDocs " .
     "--exclude debian*.img.ext2 " .
     "--exclude DCIM* ";
    system "ssh root@`n900` chown -R user.users /home/user/MyDocs";
  }
}

sub default_cpu_limits(){
  if(ask 'set DEFAULT CPU limits to 500/1000 and voltage to ideal?'){
    system "ssh root@`n900` 'kernel-config load ideal; " .
     "kernel-config limits 500 1000; kernel-config default'";
  }
}

sub xterm_color(){
  if(ask 'Set xterm colors to green-on-black?'){
    my $bg = 'black';
    my $fg = 'green';
    my $bg_key = '/apps/osso/xterm/background';
    my $fg_key = '/apps/osso/xterm/foreground';
    system "ssh root@`n900` '" .
      "gconftool-2 -s -t string \"$bg_key\" \"$bg\"; " .
      "gconftool-2 -s -t string \"$fg_key\" \"$fg\"; " .
      "'";
  }
}

sub xterm_virtual_kb(){
  if(ask 'Set xterm virtual keys?'){
    my $keylabels_gconf = '/apps/osso/xterm/key_labels';
    my $keys_gconf = '/apps/osso/xterm/keys';

    #Key Label, Key Value
    my @keys = (
      'Tab' => 'Tab',
      'Esc' => 'Escape',
      '~'   => 'asciitilde',
      '|'   => 'bar',
      '<'   => 'less',
      '>'   => 'greater',
      '^'   => 'asciicircum',
      '\`'  => 'grave',
      '\{'  => 'braceleft',
      '\}'  => 'braceright',
      '\['  => 'bracketleft',
      '\]'  => 'bracketright',
      'pgU' => 'Prior',
      'pgD' => 'Next',
      'Ent' => 'Return',
    );

    my ($key_labels, $key_values);
    for (my $i=0; $i<@keys; $i+=2){
      $key_labels .= $keys[$i];
      $key_values .= $keys[$i+1];
      if($i+2 < @keys){
        $key_labels .= ',';
        $key_values .= ',';
      }
    }

    $key_labels = "[$key_labels]";
    $key_values = "[$key_values]";

    print "Current xterm virtual keys:\n";
    system "echo -n Labels:; ssh root@`n900` gconftool-2 -g $keylabels_gconf";
    system "echo -n Values:; ssh root@`n900` gconftool-2 -g $keys_gconf";

    print "\n";

    print "Setting to:\nLabels:$key_labels\nValues:$key_values\n";

    system "ssh root@`n900` 'gconftool-2 -s $keylabels_gconf -t list ".
      "--list-type=string \"$key_labels\"'";
    system "ssh root@`n900` 'gconftool-2 -s $keys_gconf -t list ".
      "--list-type=string \"$key_values\"'";
  }
}

sub configure_desktop(){
  if(ask 'Replace all desktop shortcuts {and desktop-cmd-exec configs}?'){
    system "ssh root@`n900` pseudo configure-desktop.pl";
    
    print "\n\n";
    print "pkill hildon-desktop (auto-restarts with new positions)? [y/N] ";
    my $response = <STDIN>;
    chomp $response;
    if(lc $response eq 'y'){
      system "ssh root@`n900` pkill hildon-desktop";
    }else{
      print "skipped\n";
    }
  }
}

sub add_music_symlinks(){
  if(ask 'Add /media/mmc1/Music -> /home/wolke/Desktop/Music symlinks?'){
    system "ssh root@`n900` '".
      "mkdir -p /home/wolke/Desktop/Music; ".
      "ln -s /media/mmc1/Music/Library /home/wolke/Desktop/Music/; ".
      "ln -s /media/mmc1/Music/flacmirror /home/wolke/Desktop/Music/; ".
    "'";
  }
}

sub hosts(){
  if(ask 'Set hostname to wolke-n900 and setup escribe hosts?'){
    system "ssh root@`n900` '".
        "OLD=\$HOSTNAME; ".
        "NEW=wolke-n900; ".
        "echo \$NEW | tee /etc/hostname; ".
        "cat /etc/hosts | sed s/\$OLD/\$NEW/g | tee /etc/hosts; ".
        "/home/user/bin/pseudo escribe-hosts; ".
    "'";
  }
}

sub remember(){
  print "
This is a list of unexposed stuff to manually configure:
1) Phone talking app -> top menu -> Turning Control ->
   Display orientation -> Landscape
2) Turn off power saving mode on home wifi {P.S.M sux if you wanna ssh}
   Settings -> Internet Connections -> Connections ->
   SSID {e.g. Flipsafad} -> Edit -> Next -> Next -> Next ->
   Advanced -> Other -> Power saving: Off -> Yes -> Save
   ALSO: Internet Connections, automatic: CELLULAR, Never, Dont switch to wifi
3) manually change the background once if you cant programmatically
";
}

sub reflash(){
  print '(see instructions; do steps 1-3 first)';
  if(ask 'Reflash and completely wipe phone?'){
    system './utils/reflash.pl';
    print "If youre doing the full install,\n";
    print "turn the phone on and setup rootsh,\n";
    print "and connect the phone to the local network before continuing\n";
  }
}

sub ssh_setup(){
  if(ask 'Setup SSH keys?'){
    system './utils/keygen.pl';
  }
  my $mac = '42:c6:65:ac:8b:bd';

  print "Normally, the usb mac is randomly generated,
    but you can make it be the same.\n";

  if(ask "Make usb mac address $mac {was randomly generated on an n900}?"){
    system "ssh root@`n900` '" .
      "echo options g_nokia host_addr=$mac | tee /etc/modprobe.d/g_nokia'";
  }
}

sub format_mydocs_ext3(){
  if(ask 'UTTERLY DESTROY MyDocs (photos!) and format ext3?'){
    system "./utils/format_emmc_ext3.pl";
  }
}

sub reboot_phone(){
  if(ask 'reboot phone?'){
    system "ssh root@`n900` 'dbus-send --system --print-reply " .
     "--dest=com.nokia.dsme " .
     "/com/nokia/dsme com.nokia.dsme.request.req_reboot &' &";
  }
}

sub restore_backup(){
  if(ask 'Restore some things from the latest microSD card backup?'){
    system "./utils/backup_restore.pl";
  }
}

###############################
###############################
###############################
#D%ui%

#LOAD SUBROUTINE BLACK MAGIC
#Takes a subrouting name and returns a
#subroutine reference to a real sub, or undef if
#no suitable sub can be found
#
#Never dies -> Lives forever
sub magicSub($){
    my $name = shift;
    my $magic;

    eval{
        $magic = \&{$name};
    };

    if($@ or not defined &{$magic}){
        return undef;
    }else{
        return $magic;
    }
};

sub callMagicSub($){
  my $sub_name = shift;
  my $sub = magicSub $sub_name;
  if($sub){
    &{$sub}();
  }else{
    die "unknown subroutine: $sub_name\n";
  }
}

#parse the above into 3 different data structures:
# a hash of keys->subroutines,
# an array of all the subroutines in the order they should run,
# a 3-d array of the above split into sections delimited by 'header's:
#  there is one array for each of the 5 sections,
#  each of which contains arrays of 3 elements for each line
sub parse_utils(){
  my $sectionIndex = -1;
  for(my $i=0; $i<@utils; $i++){
    if($utils[$i] eq 'header'){
      $i++;
      $sectionIndex++;
      $headers[$sectionIndex] = $utils[$i];
      next;
    }

    my $index = $utils[$i];
    $i++;
    my $key = $utils[$i];
    $i++;
    my $sub = $utils[$i];

    if(defined $keys{$key}){
      my $old_sub = $keys{$key};
      die "Duplicate bindings for key $key: $sub and $old_sub\n";
    }
    $keys{$key} = $sub;
    if($index =~ /^\d+$/){
      $order[$index-1] = $sub;
    }
  
    my @arr = ($index, $key, $sub);
    push @{$sections[$sectionIndex]}, \@arr;
  }
}

#Gets a single key
sub key(){
  my $BSD = -f '/vmunix';
  if ($BSD) {
    system "stty cbreak /dev/tty 2>&1";
  }else {
    system "stty", '-icanon', 'eol', "\001";
  }
  my $key = getc(STDIN);
  if ($BSD) {
    system "stty -cbreak /dev/tty 2>&1";
  }
  else {
    system "stty", 'icanon';
    system "stty", 'eol', '^@'; # ascii null
  }
  return $key;
}

sub ui_cmd_prompt(){
  print_utils_ui();
  
  print "Press a key (dont worry, we'll double-check again after): ";
  my $key = lc key();
  handleCmd $key;
}

sub handleCmd($){
  my $key = shift;
  if($key eq "\n"){
    return;
  }
  print "\n\n";
  my $sub = $keys{$key};
  if(defined $sub){
    $sub =~ s/^([a-zA-Z0-9_-]+).*$/$1/sxi;
    callMagicSub $sub;
  }else{
    print "Unrecognized key: '$key'\n";
  }
  print "\n";
  print "press any key to continue";
  key();
}

sub ask($){
  my $msg = shift;
  print "\n\n$msg [y/N] ";
  my $response = <STDIN>;
  chomp $response;
  if(lc $response eq 'y'){
    return 1;
  }else{
    print "skipped\n";
    return 0;
  }
}

sub is_term_size_installed(){
  eval "use Term::Size::Perl";
  if($@){
    return 0;
  }else{
    return 1;
  }
}

sub get_term_width(){
  eval "use Term::Size::Perl; \$_ = Term::Size::Perl::chars";
  if($@ or $_ !~ /^\d+$/){
    return 80;
  }else{
    return $_;
  }
}

sub print_section($$$$\@\@\@){
  my $term_width = shift;
  my $left_header = shift;
  my $middle_header = shift;
  my $right_header = shift;
  my @left = @{shift()};
  my @middle = @{shift()};
  my @right = @{shift()};

  my $max_left_len = length $left_header;
  for my $arr(@left){
    my ($index, $key, $sub) = @{$arr};
    my $len = 3+length $sub;
    $max_left_len = $len if $len > $max_left_len;
  }
  my $max_middle_len = length $middle_header;
  for my $arr(@middle){
    my ($index, $key, $sub) = @{$arr};
    my $len = 3+length $sub;
    $max_middle_len = $len if $len > $max_middle_len;
  }
  my $max_right_len = length $right_header;
  for my $arr(@right){
    my ($index, $key, $sub) = @{$arr};
    my $len = 3+length $sub;
    $max_right_len = $len if $len > $max_right_len;
  }

  $left_header .= ' 'x(1+$max_left_len-length $left_header);
  $middle_header .= ' 'x(1+$max_middle_len-length $middle_header);
  $right_header .= ' 'x(1+$max_right_len-length $right_header);

  my $len = length "|$left_header|$middle_header|$right_header|";
  $len = $term_width - $len;
  $left_header .= ' ' x($len/3) . ($len%3>0?' ':'');
  $middle_header .= ' ' x($len/3);
  $right_header .= ' ' x($len/3) . ($len%3==2?' ':'');

  print "|$left_header|$middle_header|$right_header|\n";

  my $max_size = 0;
  $max_size = @left if @left > $max_size;
  $max_size = @middle if @middle > $max_size;
  $max_size = @right if @right > $max_size;
  for(my $i=0; $i<$max_size; $i++){
    my $left_entry='';
    my $middle_entry='';
    my $right_entry='';

    if($i < @left){
      $left_entry = " " . ${$left[$i]}[1] . ": " . ${$left[$i]}[2];
    }
    if($i < @middle){
      $middle_entry = " " . ${$middle[$i]}[1] . ": " . ${$middle[$i]}[2];
    }
    if($i < @right){
      $right_entry = " " . ${$right[$i]}[1] . ": " . ${$right[$i]}[2];
    }

    my $lspc = 1+$max_left_len - length $left_entry;
    my $mspc = 1+$max_middle_len - length $middle_entry;
    my $rspc = 1+$max_right_len - length $right_entry;
    
    my $sum = $lspc + $mspc + $rspc;
    my $lim = $term_width -
      length "|$left_entry|$middle_entry|$right_entry|";
    while(($lspc > 0 or $mspc > 0 or $rspc > 0) and $sum > $lim){
      if($rspc > 0){
        $rspc--;
      }elsif($mspc > 0){
        $mspc--;
      }elsif($lspc > 0){
        $lspc--;
      }
      $sum = $lspc + $mspc + $rspc;
    }

    $left_entry .= ' 'x$lspc;
    $middle_entry .= ' 'x$mspc;
    $right_entry .= ' 'x$rspc;

    $len = length "|$left_entry|$middle_entry|$right_entry|";
    $len = $term_width - $len;
    $left_entry .= ' ' x($len/3) . ($len%3>0?' ':'');
    $middle_entry .= ' ' x($len/3);
    $right_entry .= ' ' x($len/3) . ($len%3==2?' ':'');
    
    print "|$left_entry|$middle_entry|$right_entry|\n";
  }


}
sub print_utils_ui(){
  system "clear";
  my $term_width = get_term_width();

  print '-'x$term_width . "\n";
  print_section($term_width,
    $headers[0], $headers[1], $headers[2],
    @{$sections[0]}, @{$sections[1]}, @{$sections[2]});
  print '-'x$term_width . "\n";
  print_section($term_width,
    $headers[3], $headers[4], $headers[5],
    @{$sections[3]}, @{$sections[4]}, @{$sections[5]});
  print '-'x$term_width . "\n";

  if(!is_term_size_installed){
    print "run 'cpan Term::Size::Perl' for terminal resize support\n";
  }
}

###############################
###############################
###############################
#E%text%

sub get_instructions_text(){
"
How to flash the rootfs AND eMMC
this is for only certain kinds of folks that do certain kinds of things

start charging the phone

1) go here:
http://tablets-dev.nokia.com/maemo-dev-env-downloads.php

Download maemo_flasher-*_i386.deb
'Maemo Flasher-3.5 Tool for Fremantle and Diablo,
 installation package for Debian based Linuxes (x86, 32-bit)'
as of July 28, 2010:
 maemo_flasher-3.5_2.5.2.2_i386.deb

2) Then go here:
http://tablets-dev.nokia.com/nokia_N900.php

Your product id might be 356938034939406 if youre elliot wolk

Download RX-51_*_PR_COMBINED_002_ARM.bin
'Latest Maemo 5 USA release for Nokia N900'
as of July 28, 2010:
 RX-51_2009SE_10.2010.19-1.002_PR_COMBINED_002_ARM.bin


Download RX-51_*.VANILLA_PR_EMMC_MR0_ARM.bin
'Latest Vanilla version of the eMMC content for Nokia N900'
as of July 28, 2010:
 RX-51_2009SE_10.2010.13-2.VANILLA_PR_EMMC_MR0_ARM.bin

3) take out the battery, put it back in, wait a sec.

this is the way the say to do it, but see below for a way that seems better:
hold u key on the keyboard
hook the phone up via usb while holding
if bright Nokia screen with usb symbol appears, let go of U key
otherwise, let go, wait 10s, unplug usb, hold u key and replug usb
repeat the above step until it works. if it really really isnt working,
charge the phone more and retry.

this may work better:
plug phone in via usb
turn phone on, being prepared to press U as soon as you see the
white Nokia screen
press and hold u on the keyboard
the nokia screen should be replaced with a Nokia screen with a usb symbol

4) run this script to reflash (choose execute-all, and wait after the flash)
   the reflash ALREADY IN THIS SCRIPT does this, more or less:
   #cd ~/Desktop/N900/config #or wherever you dled to
   #sudo dpkg -i maemo_flasher-*_i386.deb --force-architecture #64-bit is fine
   #sudo flasher-3.5 -F RX-51_*_PR_COMBINED_002_ARM.bin -f
   #sudo flasher-3.5 -F RX-51_*.VANILLA_PR_EMMC_MR0_ARM.bin -R

5) turn the phone on and get to the desktop

   when the reflash is done, it will prompt the next instruction
   e.g.: Setup SSH keys? [y/N]
   the Nokia screen will flash white, then the phone will turn off
   
   turn the phone on
   this will be somewhat slower than a normal boot,
   with most of the time spent on the five bouncing white dots
   
   when you get to the normal initial boot menu,
   (Language, Region, Time, Date) push save to dismiss it.

   if youre still connected with usb, it will ask you to switch modes.
   Select PC Suite Mode.

6) get rootsh
   connect to internet
   open the web browser
   search 'n900 rootsh downloads'
   install it
   
7) open up the terminal, and type:
   sudo gainroot
   apt-get install openssh

   connect to the local network
   (either wifi or plug in the usb cable and then run 'ifup usb0' as root)

8) continue with this script until the reboot,
   wait for the phone to be back up,
   connect the phone to the local network,
   and continue with the script again

et voila. maybe.
";
}

sub get_license_text(){
"   Restore utility for the Nokia N900.

    A silly little script, Copyright (c) 2010 Elliot Wolk

    This script is licensed under GNU GPL version 3.0 or above
    #####################################################################
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    #####################################################################
";
}

