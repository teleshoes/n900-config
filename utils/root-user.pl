#!/usr/bin/perl
use strict;
use warnings;

my $date = `date +%Y-%m-%d_%s`;
chomp $date;

my @files = ('.bashrc', '.profile', '.vimrc',
             'bin', 'resolvconf', 'openvpn',
             '.cpulimits', '.twip',
             'klomp', '.klompdb', '.klomplist', '.klomphistory', '.klompcur');
for my $file(@files){
  my $bakfile = $file . "_$date.bak";

  my $cmd;

  $cmd = "ssh root@`n900` '" .
   "gfind /root/$file -type l -delete; " .
   "mv /root/$file /root/$bakfile; " .
   "ln -s /home/user/$file /root/$file'";
  print "$cmd\n";
  system $cmd;
}
