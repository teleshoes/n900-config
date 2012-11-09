#!/usr/bin/perl
use strict;
use warnings;

my $hostName = "wolke-n900";

my $DIR = '/opt/CONFIG_FILES';
my $user = 'user';
my $group = 'users';
my $binTarget = '/usr/bin';

my @rsyncOpts = qw(
  -a  --no-owner --no-group
  --del
  --out-format=%n
);

my %symlinksToReplace = map {$_ => 1} (
);

my %changedTriggers = (
);

sub overwriteFile($$);
sub removeFile($);
sub md5sum($);

sub main(@){
  die "Usage: $0\n" if @_ > 0;
  die "hostname must be $hostName" if `hostname` ne "$hostName\n";

  my @boingFiles = `cd $DIR; ls -d %*`;
  chomp foreach @boingFiles;
  my @binFiles = `cd $DIR/bin; ls -d *`;
  chomp foreach @binFiles;
  my @filesToRemove = `cat $DIR/config-files-to-remove`;
  chomp foreach @filesToRemove;

  my %triggers;

  print "\n ---handling boing files...\n";
  for my $file(@boingFiles){
    my $dest = $file;
    $dest =~ s/%/\//g;
    my ($old, $new);
    if(defined $changedTriggers{$dest}){
      $old = md5sum $dest;
    }
    overwriteFile "$DIR/$file", $dest;
    if(defined $changedTriggers{$dest}){
      $new = md5sum $dest;
      if($old ne $new){
        print "   ADDED TRIGGER: $changedTriggers{$dest}\n";
        $triggers{$changedTriggers{$dest}} = 1;
      }
    }
  }

  print "\n ---handling bin files...\n";
  for my $file(@binFiles){
    overwriteFile "$DIR/bin/$file", "$binTarget/$file";
  }

  print "\n ---removing files to remove...\n";
  for my $file(@filesToRemove){
    chomp $file;
    removeFile $file;
  }

  print "\n ---running triggers...\n";
  for my $trigger(keys %triggers){
    print "  $trigger: \n";
    system $trigger;
  }
}

sub overwriteFile($$){
  my ($src, $dest) = @_;
  my $destDir = `dirname $dest`;
  chomp $destDir;
  system "mkdir -p $destDir";
  print "\n%%% $dest\n";
  if(-d $src){
    system 'rsync', @rsyncOpts, "$src/", "$dest";
  }else{
    system 'rsync', @rsyncOpts, "$src", "$dest";
  }

  if(defined $symlinksToReplace{$dest} and -l $dest){
    my $realDest = readlink $dest;
    system "cp", $realDest, $dest;
  }

  if($destDir =~ /^\/home\/$user/){
    system "chown -R $user.$group $dest";
    system "chown $user.$group $destDir";
  }else{
    system "chown -R root.root $dest";
    system "chown root.root $destDir";
  }
}

sub removeFile($){
  my $file = shift;
  if(-e $file){
    if(-d $file){
      $file =~ s/\/$//;
      $file .= '/';
      print "\nremoving these files in $file:\n";
      system "find $file";
    }else{
      print "\nremoving $file\n";
    }
    system "rm -r $file";
  }
}

sub md5sum($){
  my $file = shift;
  my $out;
  if(-d $file){
    $out = `md5sum "$file"/* 2>/dev/null | sort`;
  }else{
    $out = `md5sum $file 2>/dev/null`;
    chomp $out;
  }
  return $out;
}
&main(@ARGV);
