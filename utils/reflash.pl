#!/usr/bin/perl
use strict;
use warnings;

sub prompt($){
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

if(prompt 'Are you absolutely sure you know what youre doing?'){
  print "To continue, type 'erase everything' without the quotes\n";
  my $response = <STDIN>;
  chomp $response;
  if(lc $response eq 'erase everything'){
    chdir "flashing";
    print "seriously killing everything\n";
    print "installing flasher\n";
    system "sudo dpkg --force-architecture -i maemo_flasher-*_i386.deb";
    print "flashing rootfs\n";
    system "sudo flasher-3.5 -F RX-51_*_PR_COMBINED_002_ARM.bin -f";
    print "flashing eMMC, this takes awhile\n";
    exec "sudo flasher-3.5 -F RX-51_*.VANILLA_PR_EMMC_MR0_ARM.bin -f -R";
  }else{
    print "skipped\n";
  }
}

