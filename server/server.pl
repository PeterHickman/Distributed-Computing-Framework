#!/usr/bin/perl -w

use strict;
use Frontier::Daemon;
use MIME::Base64;

################################################################################

my %users;
my @work;

my $status_good = 0;
my $status_bad  = 999;

################################################################################

loaddata();
startserver();
exit(0);

################################################################################

sub startserver {
    logmessage("Starting the DCF server");

    Frontier::Daemon->new(
        LocalPort => 88,
        methods   => {
            adduser    => \&adduser,
            fetchwork  => \&fetchwork,
            returnwork => \&returnwork
        },
      )
      or die "Unable to start DCF server: $!\n";
}

################################################################################

sub loaddata {
    open( FILE, "users.txt" );
    while (<FILE>) {
        chomp;
        if (m/,/) {
            my ( $k, $v ) = split( ",", $_, 2 );
            $users{$k} = $v;
        }
    }
    close(FILE);

    opendir( DIR, "worktodo" );
    my @files = readdir(DIR);
    closedir(DIR);

    foreach my $file (@files) {
        if ( $file =~ m/\.dat$/gi ) {
            if ( -e "workdone/$file" ) {
                unlink("worktodo/$file");
            }
            else {
                push( @work, $file );
            }
        }
    }

    logmessage( "There are " . scalar(@work) . " jobs to do" );
}

################################################################################

sub logmessage {
    my $text = shift;

    my $message = '[' . localtime() . '] ' . $text . "\n";

    open( LOGFILE, '>>logfile.txt' );
    print LOGFILE $message;
    print $message;
    close(LOGFILE);
}

################################################################################
# Start of the XML-RCP functions
################################################################################

sub adduser {
    my $name = shift;

    my $message;

    if ( defined( $users{$name} ) ) {
        $message = 'Welcome back ' . $name;
    }
    else {
        $users{$name} = '' . localtime();
        $message = $name . ' joined on ' . $users{$name};
        logmessage("New user $name");

        open( FILE, ">users.txt" );
        foreach ( keys(%users) ) {
            print FILE "$_,$users{$_}\n";
        }
        close(FILE);
    }

    return { status => $status_good, text => $message, data => '' };
}

################################################################################

sub fetchwork {
    my $name = shift;

    my $status;
    my $text;
    my $data;
    my $temp;

    if ( scalar(@work) == 0 ) {
        $status = $status_bad;
        $text   = 'There is no more work to assign';
        $data   = '';
    }
    else {
        $status = $status_good;
        $text   = shift(@work);
        open( FILE, "worktodo/$text" );
        read( FILE, $temp, ( stat("worktodo/$text") )[7] );
        $data = Frontier::RPC2::Base64->new( encode_base64($temp) );
        close(FILE);
        logmessage("$name given $text");
    }

    return { status => $status, text => $text, data => $data };
}

################################################################################

sub returnwork {
    my $user = shift;
    my $name = shift;
    my $data = shift;

    logmessage("$user returns $name");

    open( FILE, ">workdone/$name" ) or die "Unable to create file workdone/$name\n";
    print FILE decode_base64( $data->value() );
    close(FILE);

    return { status => $status_good, text => "Work $name received from $user", data => '' };
}

################################################################################
