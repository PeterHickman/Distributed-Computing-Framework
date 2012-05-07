DCF - Distributed Computing Framework - Version 1.0
---------------------------------------------------

DCF is a simple proof of concept code for a distributed 
computing framework a la Set@Home, Genome@Home etc.

What it does and how to use it
------------------------------
Put the server directory on your server and create two
directories below it. One called worktodo and another
called workdone (case is important on Unix based systems
but Windows will take anything).

Place all your work units to be processed in the worktodo
directory. Each work unit filename must be a sequence digits
ending with a '.dat'. Both the client and the server are 
expectiong the filenames to match this standard.

Now run the server. It will count the number of work units 
available and wait for the client to connect.

The client needs more configuration. The $options{url} = 
'http://127.0.0.1:88/RPC2' line needs to be changed to 
the correct url, you just need to change the 127.0.0.1
and the port number. 88 was chosen for no particular 
reason if you find that firewalls are getting in the way
change it to port 80 on both the client and the server.

Leave the '/RPC2' as it is.

The the subroutine dothework() there is a system call to
the program that will do the actual work. In this case a 
perl script called fred.pl. This is invoked this way so 
that Windows systems will be able to run the program.

 my $r = system("perl fred.pl $config{job}");

Change the 'perl fred.pl' part of the line to your client.

By way of example
-----------------
From a clean install change the url and port number if 
necessary and on the server run the setup.pl script. This
will place 100 dummy work units in the server's worktodo
directory.

Start the server.

Now start the client. The client will ask you for a user 
name, this is just used by the server to identify who was
given and returned the work unit.

Once running the client will get a work unit from the server
and place it in the client's worktodo directory and call the
fred.pl script to process it. Once fred.pl has completed the
client will send it back to the server and start over again.

Eventually all the work units on the server will be processed 
and the client will quit as there is no work to do.

Processing a work unit
----------------------
The fred.pl script is an example of a work unit processor. It has
only one argument, the name of the work unit to process. It reads
this file from the client's worktodo directory. Processes the 
contents and write the results to the workdone directory with the
same filename as the input and deletes the input file.

What it doesn't do
------------------
Much of the slickness of the more 'professional' distributed computing
projects is absent here.

 * Doesn't go into background
 * It is not crash resistant, although fred.pl could implement this
 * Does not farm out the same unit to several clients for crosschecks
 * The server keeps all it's data in memory which will eat resources
 * You could probably crash it quite easily
 * It probably doesn't scale too well
 * No work unit caching on the client

What is it good for
-------------------
If you have your own project then this will handle the distributed part
without you having to worry about it.

It is written in Perl and uses XML-RPC to communicate. This means
it will run on almost anything and can talk over the internet to any 
other system.

XML-RPC is available for almost all languages and platforms so the 
client and server can easily be rewritten if needs be.

What next
---------
By using a database the server could handle more but might have to become
more OS specific (ie Linux).

Fred.pl could be coded to show how to survive a crash.

The client could cache work units.
