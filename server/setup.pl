#!/usr/bin/perl -w

mkdir "worktodo" unless -d "worktodo";
mkdir "workdone" unless -d "workdone";

foreach ( 1 .. 100 ) {
    open( FILE, ">worktodo/$_.dat" );
    print FILE "Something to do\n";
    close(FILE);
}
