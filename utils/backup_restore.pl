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

my $backupDir = '/media/mmc1/Backup';

print "fetching the latest dir, will prompt before doing anything\n";
my $lDir = "$backupDir/Latest";
my $link = `ssh root@\`n900\` ls -l $lDir`;
if($link =~ /-> $backupDir\/([0-9_-]+)\n$/){
  $lDir = "$backupDir/$1";
  print "Latest backup date is: $1\n";
}else{
  die "Unknown backup date; is microSD mounted?\n";
}

if(prompt "OVERWRITE contacts with osso-addressbook-backup?"){
  my $file = "$lDir/osso-addressbook-backup";
  system "ssh root@`n900` 'echo " .
    "\"osso-addressbook-backup -i $file\"" .
    " | su - user'";
}

if(prompt "OVERWRITE cavestory save profile(s)?"){
  my $dest = '/home/user/MyDocs/Games/CaveStory/n900';
  system "ssh root@`n900` cp -a $lDir/home/user/CaveStory/* $dest";
  system "ssh root@`n900` chown user.users $dest -R";
}

if(prompt "OVERWRITE lmarbles profile and save?"){
  my @files = (
    '/home/user/.lgames/lmarbles.conf',
    '/home/user/.lmarbles_profile',
    '/home/user/.lmarbles_state');
  my $cmd = '';
  for my $file(@files){
    $cmd .= "cp $lDir/$file $file; ";
  }
  $cmd .= "chown user.users /home/user/.lmarbles* /home/user/.lgames -R; ";
  system "ssh root@`n900` '$cmd'";
}

if(prompt "Copy rtcom event logger db {texts/calls/etc}? backup will be made"){
  my $dir = "/home/user/.rtcom-eventlogger";
  my $srcFile = "$lDir/$dir/el-v1.db";
  my $destFile = "$dir/el-v1.db";
  my $backupFile = "$dir/el-v1.db.bak" . time;
  print "Backup will be made at $backupFile\n";
  system "ssh root@`n900` '" .
    "cp $destFile $backupFile; " .
    "cp $srcFile $destFile'";
  if(prompt "restart hildon desktop {may fail, restart}?"){
    system "ssh root@`n900` killall hildon-desktop";
  }
}
