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

my $DIR = '/home/wolke/Code/n900';
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
#BOTTOM
'header' => "Copy Files/Settings:",
  '23' => ';' => 'remember',
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
  if(length $arg == 1){
    handleCmd $arg;
  }else{
    callMagicSub $arg;
  }
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

#####

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
4) Settings -> Text Input -> Auto-capitalization off
";
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

