#!/usr/bin/perl -w

$file = $ARGV[0];

if( -e "worktodo/$file" ) {
	# --- Read in the data

	open(FILE, "<worktodo/$file");
	while(<FILE>) {
		chomp();
		$text .= $_;
	}
	close(FILE);

	# --- Do something with the input data

	$text = 'You said \'' . $text . '\'';

	# --- Delete the input file

	unlink("worktodo/$file");

	# --- Write the results

	open(FILE, ">workdone/$file");
	print FILE $text;
	close(FILE);
}
