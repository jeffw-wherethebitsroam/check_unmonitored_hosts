#!/usr/bin/perl

use strict;
use DBI;
use Getopt::Std;

# should probably read this info from /usr/local/nagios/etc/opsview.defaults
# DB for Opsview
my $dbuser = "opsview";
my $dbpasswd = "password";
my $db = "opsview";
my $dbhost = "localhost";
my $dbi = "dbi:mysql";

sub usage()
{
        print "Usage: $0 -w <warning> -c <critical> <subnet in CIDR form> [<additional subnet>, ...]\n";
}

# Command line arguments
our ( $opt_h, $opt_w, $opt_c );
getopts("hw:c:");
if ($opt_h) {
    usage();
    exit 0;
}
if ( !defined($opt_w) or !defined($opt_c) ) {
    print "Must specify both warning and critical values!\n\n";
    usage();
    exit 3;
}
elsif ( $opt_w > $opt_c ) {
    print "Warning value must not be greater than critical value\n\n";
    usage();
    exit 3;
}

# Must have opt_w and opt_c
my $warning  = $opt_w;
my $critical = $opt_c;

unless ($ARGV[0]) {
        usage();
        exit 3;
}

# create a hash of existing IPs
my %ips;

my $dbh = DBI->connect("$dbi:database=$db;host=$dbhost", $dbuser, $dbpasswd);

my $sql = "SELECT name, ip, other_addresses FROM hosts";
my $sth = $dbh->prepare($sql);
$sth->execute;

while (my ($name, $ip, $other_addresses) = $sth->fetchrow_array)
{
        $ips{$ip} = $name;

        # trim the other_addresses and process
        $other_addresses =~ s/^\s+//;
        $other_addresses =~ s/\s+$//;
        foreach my $address (split(/\s*,\s*/, $other_addresses))
        {
                $ips{$address} = $name;
        }
}

my @unmonitored;

while (my $subnet = shift)
{
        # now use fping to find the hosts
        my $new_hosts = `/usr/sbin/fping -a -r 1 -g $subnet`;

        foreach my $ip (split(/\n/, $new_hosts))
        {
                unless ($ips{$ip})
                {
                        push @unmonitored, $ip;
                }
        }
}

my $count = scalar(@unmonitored);
if ($count > $critical)
{
        print "CRITICAL - $count unmonitored hosts: ", join(',', @unmonitored), "\n";
        exit 2;
}
elsif ($count > $warning)
{
        print "WARNING - $count unmonitored hosts: ", join(',', @unmonitored), "\n";
        exit 1;
}
else
{
        print "OK - $count unmonitored hosts\n";
        exit 0;
}
