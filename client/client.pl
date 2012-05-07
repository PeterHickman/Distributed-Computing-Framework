#!/usr/bin/perl -w

################################################################################
# Program : client (Distributed Computing Framework client)
#
# Version : 1.000
# Dated   : 25th September 2001
# Author  : Peter Hickman (peterhi@shake.demon.co.uk)
#
# Description
# -----------
#
################################################################################

use strict;
use Frontier::Client;
use MIME::Base64;

################################################################################

my %options;

$options{url}         = 'http://127.0.0.1:88/RPC2';
$options{proxy}       = '';
$options{encoding}    = 'utf-8';
$options{use_objects} = 0;
$options{debug}       = 0;

################################################################################

my %config;

################################################################################

initialisesystem();
writeconfig();

while ( 1 == 1 ) {
    worktosend();
    worktodo();
    dothework();
}

exit(0);

################################################################################

sub initialisesystem {
    if ( -e "config.txt" ) {

        # --- Read the config file

        open( FILE, "config.txt" ) or die "Unable to read 'config.txt': $!";
        while ( my $line = <FILE> ) {
            chomp;
            my ( $k, $v ) = split( '=', $line, 2 );
            $config{ lc $k } = $v;
        }
        close(FILE);

        adduser() unless $config{user};
    }
    else {
        logmessage("Unable to locate the config.txt file");
    }

    mkdir "worktodo" unless -d "worktodo";
    mkdir "workdone" unless -d "workdone";
}

################################################################################

sub writeconfig {
    open( FILE, ">config.txt" ) or die "Unable to write to 'config.txt': $!";
    foreach my $key ( keys %config ) {
        print FILE "$key=$config{$key}\n";
    }
    close(FILE);
}

################################################################################

sub worktosend {
    opendir( DIR, "workdone/" ) or die "Unable to read 'workdone': $!";
    my @files = readdir(DIR);
    closedir(DIR);

    foreach my $file (@files) {
        if ( $file =~ m/^[0-9]+\.dat$/i ) { sendfile($file); }
    }
}

################################################################################

sub worktodo {
    opendir( DIR, "worktodo/" ) or die "Unable to read 'worktodo': $!";
    my @files = readdir(DIR);
    closedir(DIR);

    $config{job} = '';

    foreach my $file (@files) {
        if ( $file =~ m/^[0-9]+\.dat$/i ) {
            logmessage("Selected $file for processing");
            $config{job} = $file;
            last;
        }
    }

    getwork() unless $config{job};
}

################################################################################

sub dothework {
    if ( $config{job} eq '' ) {
        logmessage("No job to process");
        exit(0);
    }
    else {
        my $r = system("perl fred.pl $config{job}");

        if ( -e "worktodo/$config{job}" ) { unlink("worktodo/$config{job}"); }

        if ( $r == 0 ) {
            logmessage("Job $config{job} processed correctly");
        }
        else {
            logmessage("Job $config{job} failed to process");
        }
    }
}

################################################################################

sub logmessage {
    my $text = shift;

    print '[' . localtime() . '] ' . $text . "\n";
}

################################################################################
# These are to be the XML-RPC calls
################################################################################

sub adduser {
    $config{user} = '';

    while ( $config{user} eq '' ) {
        print "Enter your user name: ";
        $config{user} = <STDIN>;
        chomp( $config{user} );
        $config{user} =~ s/[ \t]//gi;
    }

    my $c;

    my $client = Frontier::Client->new(%options);

    eval { $c = $client->call( 'adduser', $config{user} ) };
    if ( validatereturn( $@, $c ) ) {
        if ( $c->{status} == 0 ) {
            logmessage( $c->{text} );
        }
    }
    else {
        logmessage("Unable to add a user to the project");
        delete( $config{user} );
    }
}

################################################################################

sub sendfile {
    my $file = shift;

    logmessage("Sending $file");

    my $c;

    my $client = Frontier::Client->new(%options);

    my $data;
    my $temp;

    open( FILE, "workdone/$file" ) or die "Unable to open 'workdone/$file': $!";
    read( FILE, $temp, ( stat("workdone/$file") )[7] );
    close(FILE);

    $data = Frontier::RPC2::Base64->new( encode_base64($temp) );

    eval { $c = $client->call( 'returnwork', $config{user}, $file, $data ) };
    if ( validatereturn( $@, $c ) ) {
        logmessage("Returned $file");
        unlink("workdone/$file");
    }
    else {
        logmessage("Unable to send work");
    }
}

################################################################################

sub getwork {
    logmessage("Getting work from the server");

    my $c;

    my $client = Frontier::Client->new(%options);

    eval { $c = $client->call( 'fetchwork', $config{user} ) };
    if ( validatereturn( $@, $c ) ) {
        if ( $c->{status} == 0 ) {
            logmessage("Received $c->{text}");
            open( FILE, ">worktodo/$c->{text}" ) or die "Unable to create file worktodo/$c->{text}\n";
            print FILE decode_base64( $c->{data}->value() );
            close(FILE);

            $config{job} = $c->{text};
        }
        else {
            logmessage( $c->{text} );
        }
    }
    else {
        logmessage("Unable to fetch new work");
    }
}

################################################################################
# Validate the message returned from the XML-RPC server. Yes we are paranoid!
################################################################################

sub validatereturn {
    my ( $error, $ref ) = @_;

    my $r = undef;

    if ($error) {
        logmessage("XML-RPC call failed: $error");
    }
    else {
        if ( ref($ref) eq 'HASH' ) {
            if ( scalar( keys( %{$ref} ) ) != 3 ) {
                logmessage("XML-RPC call returned incorrect structure size");
            }
            else {
                if ( defined( $ref->{status} ) and defined( $ref->{data} ) and defined( $ref->{text} ) ) {
                    $r = 1;
                }
                else {
                    logmessage("XML-RPC call returned incorrect structure members");
                }
            }
        }
        else {
            logmessage("XML-RPC call returned wrong structure");
        }
    }

    return $r;
}

################################################################################
