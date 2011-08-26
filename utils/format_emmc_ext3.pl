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
  print "This will probably brick the phone.\n";
  print "To continue, type 'destroy mydocs' without the quotes\n";
  my $response = <STDIN>;
  chomp $response;
  if(lc $response eq 'destroy mydocs'){
    print "ok, you crazy\n";

    print "repartitioning p1 as ext3\n";
    system "ssh root@`n900` '" .
      "umount -l /home/user/MyDocs; " .
      "sleep 1; " .
      "mkfs.ext3 /dev/mmcblk0p1; " .
      "mount -t ext3 /dev/mmcblk0p1 /home/user/MyDocs; " .
      "mkdir /home/user/MyDocs/DCIM; " .
      "chown user.users /home/user/MyDocs/DCIM" .
      "'";
  }else{
    print "skipped\n";
  }
}

