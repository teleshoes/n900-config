#!/usr/bin/perl
use strict;
use warnings;

my @jobs = qw();

my @packagesToRemove = qw(
  tutorial-home-applet
);

my %pkgGroups = (
  '1' => [qw(
    openssh kernel-power-settings bash vim
    diffutils-gnu findutils-gnu grep-gnu rsync wget
    coreutils-gnu tar-gnu python-location
    busybox-power
  )],
  '2' => [qw(
    x11vnc ping curl openvpn git-core perl-modules make unzip less
    libterm-readkey-perl xmodmap

    swappolube-nogui

    mobilehotspot fmms fapn
    phone-control gstreamer-tools
    pidgin pidgin-maemo-docklet fennec transmission claws-mail
    fbreader evince
    gconf-editor task-swapper

    ines drnoksnes nxengine

    mplayer mediabox
    gstreamer0.10-flac libflac8 ogg-support

    desktop-cmd-exec systeminfowidget personal-ip-address bluezwitch
    flashlight-applet simple-brightness-applet wifi-switcher
    shortcutd ringtoned
  )],
  '3navit' => [qw(
    libfreetype6-navit navit navit-graphics-qt-qpainter navit-gui-qml
    gdb espeak
  )],
);

my $repoDir = "$ENV{HOME}/Code/n900/repos";
my $debDir = "$ENV{HOME}/Code/n900/debs-custom";
my $debDestPrefix = '/opt';
my $env = '';

sub runPhone(@){
  system "n900", "-s", @_;
  die "error running 'n900 -s @_'\n" if $? != 0;
}
sub readProcPhone(@){
  return `n900 -s @_`;
  die "error running 'n900 -s @_'\n" if $? != 0;
}
sub host(){
  my $host = `n900`;
  chomp $host;
  return $host;
}

sub installPackages();
sub removePackages();
sub setupRepos();
sub installDebs();

sub main(@){
  my $arg = shift;
  $arg = 'all' if not defined $arg;
  if(@_ > 0 or $arg !~ /^(all|repos|packages|remove|debs)$/){
    die "Usage: $0 [all|repos|packages|remove|debs]\n";
  }
  if($arg =~ /^(all|repos)$/){
    if(setupRepos()){
      runPhone "$env apt-get update";
    }
  }
  installPackages() if $arg =~ /^(all|packages)$/;
  removePackages() if $arg =~ /^(all|remove)$/;
  installDebs() if $arg =~ /^(all|debs)$/;
}


sub getRepos(){
  #important to sort the files and not the lines
  my $cmd = "'ls /etc/apt/sources.list.d/*.list | sort | xargs cat'";
  return readProcPhone $cmd;
}

sub setupRepos(){
  my $before = getRepos();
  my $host = host();

  print "Copying $repoDir => remote\n";
  system "scp $repoDir/* root\@$host:/etc/apt/sources.list.d/";
  print "\n\n";

  print "Content of the copied lists:\n";
  system "cat $repoDir/*.list";
  print "\n\n";

  runPhone '
    echo INSTALLING KEYS:
    for x in /etc/apt/sources.list.d/*.key; do
      echo $x
      apt-key add "$x"
    done
  ';
  
  my $after = getRepos();
  return $before ne $after;
}

sub installPackages(){
  print "\n\n";
  for my $pkgGroup(sort keys %pkgGroups){
    my @packages = @{$pkgGroups{$pkgGroup}}; 
    print "Installing group[$pkgGroup]:\n----\n@packages\n----\n";
    runPhone ''
      . " $env apt-get install"
      . " -y --allow-unauthenticated"
      . " @packages";
  }
}

sub getInstalledVersion($){
  my $name = shift;
  our %packages;
  if(keys %packages == 0){
    my $dpkgStatus = readProcPhone "cat /var/lib/dpkg/status";
    for my $pkg(split "\n\n", $dpkgStatus){
      my $name = ($pkg =~ /Package: (.*)\n/) ? $1 : '';
      my $status = ($pkg =~ /Status: (.*)\n/) ? $1 : '';
      my $version = ($pkg =~ /Version: (.*)\n/) ? $1 : '';

      $packages{$name} = $version if $status eq "install ok installed";
    }
  }
  return $packages{$name};
}

sub getArchiveVersion($){
  my $debArchive = shift;
  my $status = `dpkg --info $debArchive`;
  if($status =~ /^ Version: (.*)/m){
    return $1;
  }else{
    return undef;
  }
}

sub getArchivePackageName($){
  my $debArchive = shift;
  my $status = `dpkg --info $debArchive`;
  if($status =~ /^ Package: (.*)/m){
    return $1;
  }else{
    return undef;
  }
}

sub removePackages(){
  print "\n\nInstalling the deps for removed packages to unmarkauto\n";
  my %deps;
  for my $line(readProcPhone "apt-cache depends @packagesToRemove"){
    if($line =~ /  Depends: ([^<>]*)/){
      my $pkg = $1;
      chomp $pkg;
      $deps{$pkg} = 1;
    }
  }
  for my $pkg(@packagesToRemove){
    delete $deps{$pkg};
  }
  my $depInstallCmd = "$env apt-get install \\\n";
  for my $dep(keys %deps){
    $depInstallCmd .= "  $dep \\\n";
  }
  print $depInstallCmd;
  runPhone $depInstallCmd;

  print "\n\nChecking uninstalled packages\n";
  my $removeCmd = "$env dpkg --purge --force-all";
  for my $pkg(@packagesToRemove){
    $removeCmd .= " $pkg";
  }
  if(@packagesToRemove > 0){
    runPhone $removeCmd;
  }
}

sub isAlreadyInstalled($){
  my $debFile = shift;
  my $packageName = getArchivePackageName $debFile;
  my $archiveVersion = getArchiveVersion $debFile;
  my $installedVersion = getInstalledVersion $packageName;
  if(not defined $archiveVersion or not defined $installedVersion){
    return 0;
  }else{
    return $archiveVersion eq $installedVersion;
  }
}

sub installDebs(){
  my @debs = `cd $debDir; ls */*.deb`;
  chomp foreach @debs;
  
  print "\n\nSyncing $debDestPrefix/$debDir to $debDestPrefix on dest:\n";
  my $host = host();
  system "rsync $debDir root\@$host:$debDestPrefix -av --progress --delete";

  my $count = 0;
  print "\n\nChecking installed versions\n";
  my $cmd = '';
  for my $job(@jobs){
    $cmd .= "stop $job\n";
  }
  for my $deb(@debs){
    my $localDebFile = "$debDir/$deb";
    my $remoteDebFile = "$debDestPrefix/$debDir/$deb\n";
    if(not isAlreadyInstalled($localDebFile)){
      $count++;
      print "...adding $localDebFile\n";
      $cmd .= "$env dpkg -i $remoteDebFile\n";
      $cmd .= "if [ \$? != 0 ]; then "
              . "$env apt-get -f install -y --allow-unauthenticated; "
              . "fi\n";
    }else{
      print "Skipping already installed $deb\n";
    }
  }
  for my $job(@jobs){
    $cmd .= "start $job\n";
  }

  print "\n\nInstalling debs\n";
  if($count > 0){
    runPhone "set -x; $cmd";
  }
}

&main(@ARGV);
