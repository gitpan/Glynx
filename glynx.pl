#!/usr/bin/perl
# Copyright (c) 2000 Flavio Glock <fglock@pucrs.br>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This program was based on examples in the Perl distribution,
# mainly from Gisle Aas.
# 
# If you use it/like it, send a postcard to the author. 
# Find the latest version in CPAN or http://www.pucrs.br/flavio

use Cwd 		qw(abs_path);
use Getopt::Long;
use LWP::UserAgent;
use HTTP::Cookies;
use URI::URL;
use URI::Heuristic 	qw(uf_uristr);
use LWP::MediaTypes 	qw(media_suffix);

my $VERSION = "1.024";


=head1 NAME

Glynx - a download manager. 

=head1 DESCRIPTION

Glynx makes a local image of a selected part of the internet.

It can be used to make download lists to be used with other download managers, making
a distributed download process.

It currently supports resume/retry, referer, user-agent, frames, distributed
download (see C<--slave>, C<--stop>, C<--restart>).

It partially supports: redirect (using file-copy), java,
javascript, multimedia, authentication (only basic), 
mirror, translating links to local computer (C<--makerel>),
ftp, renaming too long filenames and too deep directories,
cookies, proxy.

It does not support yet: forms

No testing so far: "https:".

Tested on Linux and NT

=head1 SYNOPSIS

=over

=item Do-everything at once:  

 $progname.pl [options] <URL>


=item Save work to finish later:   

 $progname.pl [options] --dump="dump-file" <URL>


=item Finish saved download:  

 $progname.pl [options] "download-list-file"

=item Network mode (client/slave)

=item - Clients: 

 $progname.pl [options] --dump="dump-file" <URL>


=item - Slaves (will wait until there is something to do): 

 $progname.pl [options] --slave

=back

=head1 HINTS

How to create a default configuration:

	Start the program with all command-line configurations, plus --cfg-save
	or:
 	1 - start the program with --cfg-save
	2 - edit glynx.ini file

--subst, --exclude and --loop use regular expressions.

   http://www.site.com/old.htm --subst=s/old/new/
   downloads: http://www.acme.com/new.htm

   - Note: the substitution string MUST be made of "valid URL" characters

   --exclude=/\.gif/
   will not download ".gif" files

   - Note: Multiple --exclude are allowed:

   --exclude=/gif/  --exclude=/jpeg/
   will not download ".gif" or ".jpeg" files

   It can also be written as:
   --exclude=/\.gif|\.jp.?g/i
   matching .gif, .GIF, .jpg, .jpeg, .JPG, .JPEG

   --exclude=/www\.site\.com/
   will not download links containing the site name

   http://www.site.com/bin/index.htm --prefix=http://www.site.com/bin/
   won't download outside from directory "/bin". Prefix must end with a slash "/".

   http://www.site.com/index%%%.htm --loop=%%%:0..3
   will download:
     http://www.site.com/index0.htm
     http://www.site.com/index1.htm
     http://www.site.com/index2.htm
     http://www.site.com/index3.htm

   - Note: the substitution string MUST be made of "valid URL" characters

- For multiple exclusion: use "|".

- Don't read directory-index:

   	?D=D ?D=A ?S=D ?S=A ?M=D ?M=A ?N=D ?N=A =>  \?[DSMN]=[AD] 

	To change default "exclude" pattern - put it in the configuration file

Note: "File:" item in dump file is ignored

You can filter the processing of a dump file using --prefix, --exclude, --subst

If after finishing downloading you still have ".PART._BUSY_" files in the 
base directory, rename them to ".PART" (the program should do this by itself)

Don't do this: --depth=1 --out-depth=3 because "out-depth" is an upper limit; it 
is tested after depth is generated. The right way is: --depth=4 --out-depth=3

This will do nothing:

 --dump=x graphic.gif

because the dump file gets all binary files.

Errors using https:

 [ ERROR 501 Protocol scheme 'https' is not supported => LATER ] or
 [ ERROR 501 Can't locate object method "new" via package "LWP::Protocol::https" => LATER ]

This means you need to install at least "openssl" (http://www.openssl.org), Net::SSLeay and IO::Socket::SSL


=head1 COMMAND-LINE OPTIONS

Check --help for default values.

Very basic:

  --version         Print version number and quit
  --verbose         More output
  --quiet           No output
  --help            Help page
  --cfg-save        Save configuration to file
  --base-dir=DIR    Place to load/save files

Download options are:

  --sleep=SECS      Sleep between gets, ie. go slowly
  --prefix=PREFIX   Limit URLs to those which begin with PREFIX
                    Multiple "--prefix" are allowed.
  --depth=N         Maximum depth to traverse
  --out-depth=N     Maximum depth to traverse outside of PREFIX
  --referer=URI     Set initial referer header
  --limit=N         A limit on the number documents to get
  --retry=N         Maximum number of retrys
  --timeout=SECS    Timeout value - increases on retrys
  --agent=AGENT     User agent name
  --mirror          Checks all existing files for updates
  --nomirror        Do not check for updates -- if file exists, it's ok
  --mediaext        Creates a file link, guessing the media type extension (.jpg, .gif)
                    (perl actually makes a file copy)
  --nomediaext      Do not try to change media type extension
  --makerel         Make Relative links. Links in pages will work in the
                    local computer.
  --nomakerel       Keep links as they are. Do not try to change links.
  --auth=USER:PASS  Set authentication credentials
  --cookies=FILE    Set up a cookies file (default is no cookies)
  --name-len-max    Limit filename size
  --dir-depth-max   Limit directory depth

Multi-process control:

  --slave           Wait until a download-list file is created (be a slave)
  --stop            Stop slave
  --restart         Stop and restart slave

Not implemented yet but won't generate fatal errors (compatibility with lwp-rget):

  --hier            Download into hierarchy (not all files into cwd)
  --iis             Workaround IIS 2.0 bug by sending "Accept: */*" MIME
                    header; translates backslashes (\) to forward slashes (/)
  --keepext=type    Keep file extension for MIME types (comma-separated list)
  --nospace         Translate spaces URLs (not #fragments) to underscores (_)
  --tolower         Translate all URLs to lowercase (useful with IIS servers)

Other options: (to-be better explained)

  --indexfile=FILE  Index file in a directory
  --part-suffix=.SUFFIX  Extension to use for partial downloads 
                    (example: ".Getright" ".PART")
  --dump=FILE       make download-list file, to be used later
  --dump-max=N      number of links per download-list file 
  --invalid-char=C  Character to use in substitutions for invalid characters
  --exclude=/REGEXP/i  Don't download matching URLs
                    Multiple --exclude are allowed
  --loop=REGEXP:INITIAL..FINAL  Expand a URL through substitutions 
                    (example: xx:a,b,c  xx:'01'..'10')
  --subst=s/REGEXP/VALUE/i  Substitute some string in the urls.
  --404-retry       will retry on error 404 Not Found. 
  --no404-retry     creates an empty file on error 404 Not Found.

=head1 TO-DO

More command-line compatibility with lwp-rget

Graphical user interface

=head1 COPYRIGHT

Copyright (c) 2000 Flavio Glock <fglock@pucrs.br>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
This program was based on examples in the Perl distribution.


If you use it/like it, send a postcard to the author. 

=cut




@Config_Vars = qw/DIR_DEPTH_MAX NAME_LEN_MAX COOKIES AUTH DEPTH TIMEOUT AGENT REFERER INDEXFILE SLEEP OUT_DEPTH BASE_DIR PART_SUFFIX MAX_DOCS INVALID_CHAR LOOP SUBST DUMP DUMP_MAX RETRY_MAX/;

@Config_Arrays = qw/PREFIX EXCLUDE/;

# Defaults
$AUTH =		'';
$MAKEREL = 	0;
$MIRROR =	0;
$MEDIAEXT =	0;
$DEPTH = 	0;
$TIMEOUT = 	30;
$AGENT = 	"Mozilla/3.0 (WinNT; I)";
$REFERER = 	".";
$INDEXFILE = 	"_INDEX_.HTM";
$SLEEP =	1;
$OUT_DEPTH =	0;	# opcao para maximo de niveis ao sair do site (0 = nao sai)
$BASE_DIR =	".";
$PART_SUFFIX =	"._PART_";
$MAX_DOCS =	10000;
$INVALID_CHAR = '$';
$COOKIES = 	'';
$NAME_LEN_MAX =  30;
$DIR_DEPTH_MAX = 8;

@PREFIX =	();
@EXCLUDE = 	(); 		# "/\\/tn_|\\?[DSMN]=[AD]|banner|\\.gif/i";
$LOOP = 	"";		# "~~~~:1..50";
$SUBST = 	"";		# "s/show\\.asp\\?//";

$DUMP =		"";
$DUMP_MAX =	100;
$RETRY_MAX =	5;
$RETRY_404 =	1;
$SLAVE =	0;
$STOP = 	0;
$RESTART = 	0;

# to-be configurable
$RETRY_TIMEOUT_MULTIPLIER = 2;

# Defaults de uso interno, nao configuravel
$MAX_TESTE_REPETICAO =	30;	# testa os ultimos links antes de incluir na lista
$LIST_SIZE = 	3;		# tamanho da estrutura de @links = ($url, $referer, $nivel)

$DUMP_SUFFIX = 		".grx";
$TMP_SUFFIX =		"._TMP_";
$NOT_FOUND_SUFFIX = 	"._NOT_";
$BUSY_SUFFIX = 		"._BUSY_";
$DONE_SUFFIX = 		"._DONE_";
$GLYNX_SUFFIX =		".glynx";
$BACKUP_SUFFIX = 	".bak";

$CFG_FILE =		"glynx.ini";
$NAME_TRANSLATION_FILE = "_NAMES_.HTM";

# - at startup, read file-time of $SLAVE_RESTART_FILE.
# - do a restart whenever $SLAVE_RESTART_FILE file-time changes.
# - exit whenever $SLAVE_STOP_FILE exists.

$SLAVE_STOP_FILE = 	"_STOP_$GLYNX_SUFFIX";
$SLAVE_RESTART_FILE = 	"_RESTART_$GLYNX_SUFFIX";

# deixar fora desta lista: htm html js cgi txt cfm shtml
@DEFAULT_EXCLUDE = qw/wav mov png swf css dcr doc rtf bak ra rm sfw pcx log ps bmp dvi pdf jar java class rar iso bin midi mid mod mpeg mpg mp3 avi jpg jpeg gif gz msi asf zip cdf exe tar/;
$default_exclude = "/\\." . join("\$|\\.", @DEFAULT_EXCLUDE) . "\$/i";
# print "default_exclude: $default_exclude\n";

my $progname = $0;
@myARGV = @ARGV;
$progname =~ s|.*/||;  		# only basename left
$progname =~ s/\.\w*$//; 	# strip extension if any

&read_dump ($CFG_FILE);
&get_options;
&preprocess_options;

&save_Config (\%Main_Config);
&show_Config (\%Main_Config) if $VERBOSE;


sub get_options {
    print "  [ GET_OPTIONS ]\n" if $VERBOSE;
    GetOptions(
	'version'  	=> \&print_version,
   	'help'     	=> \&usage,
	'cfg-save'	=> \&cfg_save_default,
   	'depth=i'  	=> \$DEPTH,
	'timeout=i'	=> \$TIMEOUT,
	'agent:s'	=> \$AGENT,
	'referer:s'	=> \$REFERER,
	'indexfile=s'	=> \$INDEXFILE,
	'sleep=i'  	=> \$SLEEP,
	'out-depth=i'	=> \$OUT_DEPTH,
	'base-dir=s'	=> \$BASE_DIR,
	'part-suffix=s'	=> \$PART_SUFFIX,
	'limit=i'  	=> \$MAX_DOCS,
	'invalid-char=s'	=> \$INVALID_CHAR,
	'prefix=s'	=> \@PREFIX,
	'exclude:s'	=> \@EXCLUDE,
	'loop:s'	=> \$LOOP,
	'subst:s'	=> \$SUBST,
	'dump=s'	=> \$DUMP,
	'dump-max=i'	=> \$DUMP_MAX,
	'retry=i'	=> \$RETRY_MAX,
	'404-retry!'	=> \$RETRY_404,		# --no404-retry
	'slave!'	=> \$SLAVE,
	'verbose!' 	=> \$VERBOSE,
	'quiet!'   	=> \$QUIET,
	'restart!'	=> \$RESTART,
	'stop!'		=> \$STOP,
	'mirror!'	=> \$MIRROR,
	'mediaext!'	=> \$MEDIAEXT,
	'makerel!'	=> \$MAKEREL,
	'cookies=s'	=> \$COOKIES,
	'name-len-max=i'	=> \$NAME_LEN_MAX,
	'dir-depth-max=i'	=> \$DIR_DEPTH_MAX,

	# not implemented, but exist in lwp-rget:
	'hier'     	=> \&not_implemented('hier'),
	'auth=s'   	=> \&not_implemented('auth'),
	'iis'      	=> \&not_implemented('iis'),
	'tolower'  	=> \&not_implemented('tolower'),
	'nospace'  	=> \&not_implemented('nospace'),
	'keepext=s' 	=> \&not_implemented('keepext'),
    ) || usage();

}

sub preprocess_options {
	$BASE_DIR = "." if ! $BASE_DIR;
	$BASE_DIR =~ s/\\/\//g;
	$BASE_DIR .= "/" if ! ($BASE_DIR =~ /\/$/);
	print "  [ BASE_DIR: $BASE_DIR ]\n" if $VERBOSE;

	@loop = split(":",$LOOP);
}

sub save_Config {
	my ($hashref) = @_;
	print "  [ SAVE-CONFIG ]\n" if $VERBOSE;
	foreach(@Config_Vars) {
		$$hashref{$_} = ${$_};
	}
	foreach(@Config_Arrays) {
		$$hashref{$_} = [ @{$_} ];
	}
}

sub retrieve_Config {
	my ($hashref) = @_;
	print "  [ RETRIEVE-CONFIG ]\n" if $VERBOSE;
	foreach(@Config_Vars) {
		${$_} = $$hashref{$_};
	}
	foreach(@Config_Arrays) {
		@{$_} = @{$$hashref{$_}};
	}
}

sub show_Config {
	my ($hashref) = @_;
	print "  [ SHOW-CONFIG ]\n" if $VERBOSE;
	foreach(@Config_Vars) {
		print "  [ $_: ", $$hashref{$_} , " ]\n" if $VERBOSE;
	}
	foreach(@Config_Arrays) {
		print "  [ $_: ", join(',', @{$$hashref{$_}} ) , " ]\n" if $VERBOSE;
	}
}


my $url;
$url = shift;	# optional url or input file

print "  [ $progname.pl Version $VERSION ]\n" if $VERBOSE;
print "  [ URL = $url ]\n" if $VERBOSE;

unless ($url =~ /$DUMP_SUFFIX$/) {
	$url = uf_uristr($url);
}

print "  [ URL = $url ]\n" if $VERBOSE;
print "  [ LOOP = " , join(" ", @loop), " ]\n" if $VERBOSE;

$KILL_FINISH =				1;
$KILL_RESTART =				2;
$KILL_RESTART_PROGRAM_MODIFIED =	3;
$KILL_STOP =				4;

usage() if @ARGV;

&make_restart	if $RESTART;
&make_stop	if $STOP;
&my_main;

sub my_main {
	# print "  [ STOP ]\n"	if $STOP;
	$Last_Restart =	-M "$BASE_DIR/$SLAVE_RESTART_FILE";
	# print "  [ LAST-RESTART: $Last_Restart ]\n" if $VERBOSE;
	$Last_Program_Date = -M $0;
	# print "  [ LAST-PROGRAM-DATE: $0 = $Last_Program_Date ]\n" if $VERBOSE;

	$ua = LWP::UserAgent->new;
	$ua->agent($AGENT);
	$ua->timeout($TIMEOUT);
	$ua->env_proxy();
	$ua->cookie_jar(HTTP::Cookies->new(file => "$BASE_DIR$COOKIES",
                                     autosave => 1)) if $COOKIES;

	# estrutura de @links = ($url, $referer, $nivel, ...)
	@links = ();		# coleta links para serem visitados ($url, $referer, $nivel, ...)
	$dump_nivel_zero = 1;	# if $DUMP, save last level. Reset if $SLAVE.
	$Slave_file = "";

    SLAVE_LOOP:

	@dump = ();		# gera o arquivo dump (mesma estrutura de @links)
	@retry = ();		# arquivos incompletos, para tentar novamente
	@processed = ();	# links ja visitados (lista simples)

	$num_docs = 0;
	$dump_filenum = 0;
	$retry = $RETRY_MAX;
	# $prefix = $PREFIX[0];
	$Dump_index = 0;

    if ( ($url =~ /$DUMP_SUFFIX$/) and !($url =~ /:/) ) {
	# DUMP:
	# verifica se o nome corresponde a um arquivo dump
	   if (-e "$url") 		{ $dump_filename = "$url"; }
	elsif (-e "$BASE_DIR$url") 	{ $dump_filename = "$BASE_DIR$url"; }
	elsif (-e "$url$DUMP_SUFFIX") 	{ $dump_filename = "$url$DUMP_SUFFIX"; }
	elsif (-e "$BASE_DIR$url$DUMP_SUFFIX") { $dump_filename = "$BASE_DIR$url$DUMP_SUFFIX"; }
	else  { die "  [ CAN'T FIND INPUT FILE: $url ]" }
	read_dump($dump_filename);
	# read_dump($DUMP) if $DUMP;	# evita perder informacao ???
    }
    elsif ($url) {
	# URL:
	# pega o nome do site
	$REFERER = $url unless $REFERER;
	print "  [ URL: abs: $url ]\n" if $VERBOSE;
	$u1 = URI::URL->new_abs($url, $REFERER);
	#$myhost = $u1->host; 
	#print "Host: $myhost\n";
	unless ($#PREFIX >= 0) {
		print "  [ PREFIX: abs: $PREFIX[0] ]\n" if $VERBOSE;
		$prefix = URI::URL->new_abs($PREFIX[0], $u1);
		print "  [ PREFIX: Gerado: $prefix ]\n" if $VERBOSE;
		# clear fragment, query...

		# test for invalid protocol

		eval{$prefix->userinfo('')};
		if ($eval_err = $@) {
			print "  [ PREFIX: Error: $eval_err ]\n";
			print "  [ PREFIX: Error: Possible cause: invalid protocol ]\n" if $VERBOSE;
		}
		else {
			# $prefix->params('');
			$prefix->query('');
			$prefix->fragment('');

			# removes file name
			unless ($prefix =~ /\/$/) {
				($prefix) = $prefix =~ /^(.*\/)/;
				print "  [ PREFIX: new: $prefix ]\n" if $VERBOSE;
			}
		      	# removes authentication
			if ($prefix =~ /\@/) {
				($prefix) = $prefix =~ /.*\@(.*)/;
				print "  [ PREFIX: new: $prefix ]\n" if $VERBOSE;
			}
			@PREFIX = ($prefix);
			print "  [ PREFIX: @PREFIX ]\n" unless $QUIET;
		}
		&insert_url ($url, $REFERER, $DEPTH);
	}
    }
    else {
	print "  [ NO URL ]\n" unless $QUIET;
    }

download_links_retry:

    while (@links) {
	if ($num_docs >= $MAX_DOCS) {
		print "  [ FIM: num_docs > $MAX_DOCS ]\n" if $VERBOSE;
		last;
	}
	#print "LINKS $#links -- $url --";
	($url, $referer, $nivel) = shift_list(\@links);
	$nlinks = ($#links + 1) / $LIST_SIZE;
	last if $nlinks > $MAX_DOCS;
	# print " ($url, $referer, $nivel [$nlinks] \n";
	download($url, $referer, $nivel);

	print "  [ STATUS: READ:", 
			$#processed + 1, "/",
			+(($#links + 1) / $LIST_SIZE) + $#processed + 1, 
		" LATER:", 
			+($Dump_index) / $LIST_SIZE, "/", 
			+ ($#dump + 1) / $LIST_SIZE, 
		" DEPTH:", 
			$DEPTH - $nivel, "/", 
			$DEPTH, " ]\n" unless $QUIET;

	# time to make a partial dump?
	if (	$DUMP and 
		$DUMP_MAX and
		(($#dump - $Dump_index) > ($DUMP_MAX * $LIST_SIZE) ) ) {
		&dump;
	}
    }

    # RETRY?

    if (($#retry >= 0) and ($retry > 1)) {
	print "  [ RETRY: LEVEL:", $RETRY_MAX - $retry + 2, "/$RETRY_MAX URL:", +($#retry + 1) / $LIST_SIZE, " ]\n" unless $QUIET;
  	$retry--;
  	@links = 	@retry;
	@processed =	();
	@retry =	();
	# @dump = 	();
	# $Dump_index = 	0;
	$RETRY_TIMEOUT_MULTIPLIER = 1  if $RETRY_TIMEOUT_MULTIPLIER < 1;
	$RETRY_TIMEOUT_MULTIPLIER = 10 if $RETRY_TIMEOUT_MULTIPLIER > 10;
	$TIMEOUT *= $RETRY_TIMEOUT_MULTIPLIER;
	$ua->timeout($TIMEOUT);
	print "  [ RETRY: TIMEOUT:", int($TIMEOUT), " ]\n" if $VERBOSE;
	goto download_links_retry;
    }
    else {
	if ($#retry < 0) {
		print "  [ DONE: DON'T NEED TO RETRY ]\n" if $VERBOSE;
	}
  	elsif ($retry > 1) {
		print "  [ FAILED: URL:$retry ]\n" if $VERBOSE;
	} 
	else {
		print "  [ DON'T NEED TO RETRY ]\n" if $VERBOSE;
	}
    }
	# append pending retrys to dump
	print "  [ DUMP: Move ", +($#retry + 1) / $LIST_SIZE, " from Retry to Dump ]\n" if $VERBOSE;
	@dump = (@dump, @retry);

	print "  [ DUMP: [$DUMP] ", +($#dump + 1) / $LIST_SIZE, " ]\n" if $VERBOSE;
    	while (($Dump_index <= $#dump) and $DUMP) {
		&dump;
    	}

	# check for Slave mode

SLAVE_IDLE:
    while ($SLAVE) {

	if ($Slave_file ne "") {
		# done
		&my_rename ("$Slave_file$BUSY_SUFFIX", "$Slave_file$DONE_SUFFIX") if -e "$Slave_file$BUSY_SUFFIX";
	}
	else {
		#print "  [ SLAVE: unknown slave file $Slave_file ]\n";
	}

	# timer
	# get_options;
	# read_dump ($CFG_FILE);
	&retrieve_Config (\%Main_Config);
	# &show_Config (\%Main_Config) if $VERBOSE;

	if (! $SLAVE) {
		print "  [ SLAVE: CANCELLED ]\n" unless $QUIET;
		last SLAVE_IDLE;
	}
	print "  [ SLAVE: IDLE FOR $TIMEOUT SEC ]\n" unless $QUIET;
	&my_sleep ($TIMEOUT);
	# what's in dir?
	$dir_expr = "$BASE_DIR";
	opendir DIR, $dir_expr or die "  [ SLAVE: CAN'T OPEN $dir_expr ]\n";
    		@dir =  readdir(DIR); 	
		print "  [ SLAVE: DIR: $BASE_DIR -- ", join(',',@dir), " ]\n" if $VERBOSE;
		@dir = grep { (/$DUMP_SUFFIX$/) and (-f "$BASE_DIR$_") } @dir;
	closedir DIR;
	print "  [ SLAVE: $dir_expr: $DUMP_SUFFIX -- ", join(',',@dir), " ]\n" if $VERBOSE;
	$dir_index = 0;
    SLAVE_TEST_DIR:
	while ($#dir >= $dir_index) {
		# rename file
		$dir = "$BASE_DIR$dir[$dir_index]";
		$dir_busy = "$dir$BUSY_SUFFIX";
		if (-e $dir_busy) {
			print "  [ SLAVE: $dir busy ]\n" if $VERBOSE;
			if (-e $dir) {
				# both exist -- delete one
				&my_unlink ($dir_busy);
			}
			if (-e $dir_busy) {
				$dir_index++;
				next SLAVE_TEST_DIR;
			}
		}
		&my_rename ($dir, $dir_busy);
		# check again
		unless (-e ($dir_busy)) {
				print "  [ SLAVE: can't rename $dir ]\n" unless $QUIET;
				next SLAVE_TEST_DIR;
		}
		unless (-s ($dir_busy)) {
				print "  [ SLAVE: $dir empty ]\n" unless $QUIET;
				next SLAVE_TEST_DIR;
		}
		# read dump file
		read_dump($dir_busy);
		$Slave_file = $dir;
		print "  [ SLAVE: processing $Slave_file ]\n" unless $QUIET;
		last SLAVE_IDLE;
	} # dir ok
    } # slave

    if ($SLAVE) {
	# ??? get_options;
	# read_dump ($CFG_FILE);
	&retrieve_Config (\%Main_Config);

	print "  [ SLAVE: continue processing $Slave_file ]\n" if $VERBOSE;
	$url = "";
	$dump_nivel_zero = 0;	# download level zero, even if $DUMP
	goto SLAVE_LOOP;
    }

    print "  [ END ]\n" unless $QUIET;
} # my_main

sub my_sleep {
	my ($time) = @_;
	print "  [ SLEEP $SLEEP " unless $QUIET;
	foreach ( 1 .. $time ) {
		&check_stop;
		sleep 1;
		print "." unless $QUIET;
	}
	&check_stop;
	print " done ]\n" unless $QUIET;
}

sub make_stop {
	# - do a restart whenever $SLAVE_RESTART_FILE file-time changes.
	print "  [ MAKE-STOP ]\n" if $VERBOSE;
	&my_unlink("$BASE_DIR/$SLAVE_STOP_FILE");
	&my_unlink("$BASE_DIR/$SLAVE_RESTART_FILE");
	&my_create_empty("$BASE_DIR/$SLAVE_STOP_FILE");
}

sub make_restart {
	# - exit whenever $SLAVE_STOP_FILE exists.
	print "  [ MAKE-RESTART ]\n" if $VERBOSE;
	&my_unlink("$BASE_DIR/$SLAVE_STOP_FILE");
	&my_unlink("$BASE_DIR/$SLAVE_RESTART_FILE");
	&my_create_empty("$BASE_DIR/$SLAVE_RESTART_FILE");
}

sub check_stop {
	#  --stop            Stop slave
	#  --restart         Stop and restart slave
	# - at startup, read file-time of $SLAVE_RESTART_FILE.
	# - do a restart whenever $SLAVE_RESTART_FILE file-time changes.
	# - exit whenever $SLAVE_STOP_FILE exists.
	# print "  [ SLAVE: $SLAVE -- $BASE_DIR/$SLAVE_STOP_FILE ]\n" if $VERBOSE;
	return if ! $SLAVE;
	# print "  [ SLAVE: CHECK STOP ]\n" if $VERBOSE;
	if (-e "$BASE_DIR/$SLAVE_STOP_FILE") {
		print "  [ SLAVE: STOP ]\n" if $VERBOSE;
		exit $KILL_STOP;
	}
	if (-e "$BASE_DIR/$SLAVE_RESTART_FILE") {
		$New_Restart =	-M "$BASE_DIR/$SLAVE_RESTART_FILE";
		# print "  [ LAST-RESTART: $Last_Restart -- $New_Restart ]\n" if $VERBOSE;
		if ($Last_Restart != $New_Restart) {
			print "  [ SLAVE: RESTART ]\n" if $VERBOSE;
			# exit $KILL_RESTART;
			$do_str = "$0 " . join(' ', @myARGV);
			print "  [ STARTING $do_str ]\n" if $VERBOSE;
			print "  [ RESTARTING ]\n";
			exec $do_str;
			die "done";
		}
	}
	if (-e $0) {
		# program modified?
		$New_Program_Date =	-M $0;
		# print "  [ LAST-PROGRAM-DATE: $Last_Program_Date -- $New_Program_Date ]\n" if $VERBOSE;
		if ($Last_Program_Date != $New_Program_Date) {
			print "  [ SLAVE: RESTART ]\n" if $VERBOSE;
			# exit $KILL_RESTART_PROGRAM_MODIFIED;
			$do_str = "$0 " . join(' ', @myARGV);
			print "  [ STARTING $do_str ]\n" if $VERBOSE;
			print "  [ RESTARTING ]\n";
			exec $do_str;
			die "done";
		}
	}
}

# Download List File Format:
#   // xxx      - comment
#   tag: value
#   //[any_var_name]: [value]
# Tags:
#   URL: xxx    - URL
#   //Referer:	- referrer URL
#   //Depth:	- link levels to download from the URL
# Reserved, unimplemented tags:
#   File: xxx   -- Absolute path\filename for file (DOS style slashes)
#   Desc: xxx   -- Description
#   User: xxx   -- Username
#   Pass: xxx   -- Password (encrypted)
#   Alt: xxx    -- Alternate URL (multiple)
# Names are Case-Sensitive.
# "//" is for compatibility with other download managers and may be ommitted.

sub read_dump {
	my ($dump_filename) = @_;
	# my (@tmp_prefix);
	# @tmp_prefix = @PREFIX;
	# ??? @PREFIX = ();		# will use file's prefixes

	if (! -e $dump_filename) { 
		$dump_filename = "$BASE_DIR$dump_filename"; 
		if (! -e $dump_filename) { return }
	}
	open(FILE, $dump_filename) or die "  [ DUMP: Can't open $dump_filename ]";

		#//OUT_DEPTH: 0
		#//PREFIX: http://us.a1.yimg.com/us.yimg.com/   --> ALLOW MULTIPLE
		#URL: http://us.a1.yimg.com/us.yimg.com/i/ww/m5v2.gif
		#File: D:\download_getright\us.a1.yimg.com\us.yimg.com\i\ww\m5v2.gif
		#//Referer: http://www.yahoo.com/
		#//Depth: 2

		# $dump_nivel_zero = 0;	# desabilita, pois todos os arquivos sao nivel zero.
		# $OUT_DEPTH =	1 if ($OUT_DEPTH < 1) and (! $PREFIX);	# nao sei quem e o host...

		# reset parameters
		$url =		"";
		#File: 		-- not used ???
		$referer =	$REFERER;
		$depth =	$DEPTH;	

		foreach(<FILE>) {
			chomp;
			($cmd, $opt) = split(" ", $_, 2);
			if ($cmd =~ /URL:/i) {
				# $prefix = 	$PREFIX[0];
				&insert_url ($url, $referer, $depth) if $url;
				# reset parameters
				$url = 		$opt;
				#File: 		-- not used ???
				$referer =	$Referer;
				$depth =	$Depth;	
			} 
			elsif ($cmd =~ /(\w*):/) {
				$var_name = $1;
				if ($opt =~ /^'/) { }
				else { $opt = "'" . $opt . "'"; }

				if (grep { /^$var_name$/ } @Config_Arrays) {
					eval "\push @" . $var_name . ", $opt";
					print "  [ CFG: \$$var_name = ", eval "\@" . $var_name . "[-1]", " ]\n" if $VERBOSE;
				}
				elsif ($var_name ne "DUMP") {
					eval "\$$var_name = $opt";
					print "  [ CFG: \$$var_name = $opt ]\n" if $VERBOSE;
				}
			}
		}
	close(FILE);
	# last one ...
	&insert_url ($url, $referer, $depth) if $url;

	# check if PREFIX has changed
	# $prefix = $PREFIX[0] if @PREFIX ne @tmp_prefix;
	# @PREFIX = @tmp_prefix;

	# ??? get_options;	# read back overriden command-line preferences  
}

sub dump {
  if ($DUMP) {
	$dump_links = 0;
	$dump_filenum++;

	# cria um diretorio absoluto para o Getright
	$dir = abs_path("$BASE_DIR");
	#print "$dir\n";
	$dump_filename = "$dir/$DUMP";
	$dump_filename .= $DUMP_SUFFIX if ! ($dump_filename =~ /$DUMP_SUFFIX$/);
	$dump_filename =~ s/(.*)\.(.*)/$1-$dump_filenum\.$2/ if $DUMP_MAX;

	print "  [ DUMP: $dump_filename ]\n" unless $QUIET;

	if ($#dump < 0) {
		print "  [ DUMP: EMPTY ]\n" unless $QUIET;
		&my_unlink ($dump_filename);
		return;
	}

	cfg_save($dump_filename);
	open (FILE, ">>$dump_filename");
#		print FILE <<EOT; 
#// Dump file generated by $progname.pl Version $VERSION - Copyright 2000, Flavio Glock.
#//
#//OUT_DEPTH: $OUT_DEPTH
#//PREFIX: $prefix
#//
#EOT
		while ($Dump_index <= $#dump) {
			$url =     $dump[$Dump_index++];
			$referer = $dump[$Dump_index++];
			$nivel =   $dump[$Dump_index++];
			print "  [ WRITE: $url ]\n" if $VERBOSE;
			$name = &make_filename($url);
			$filename = "$dir/$name";
			if (-e $filename) {
				if (-d $filename) {
					print "  [ ja existe diretorio: $filename ]\n" if $VERBOSE;
					$filename .= '/' . $INDEXFILE;
					print "  [ trying: $filename ]\n" if $VERBOSE;
					next if (-s $filename);
				} elsif (-s $filename) {
					print "  [ ja existe: $filename ]\n" if $VERBOSE;
					next;
				}
			}
			$filename =~ s/\//\\/g;
			print FILE <<EOT; 
URL: $url
File: $filename
//Referer: $referer
//Depth: $nivel
EOT
			$dump_links++;
			last if $DUMP_MAX and ($dump_links >= $DUMP_MAX);
		}
	close (FILE);
  }
	print "  [ DUMP: finish ]\n" if $VERBOSE;
} # end: dump

sub cfg_save_default {
	cfg_save($CFG_FILE);
}

sub cfg_save {
	my ($filename) = @_;
	# my ($tmp_prefix);
	my $file = $filename;
	if (-e $filename) { }
	elsif (-e "$BASE_DIR$filename") { $file = "$BASE_DIR$filename"; }
	open(FILE, ">$file") or
		open(FILE, ">$filename") or
			open(FILE, ">$BASE_DIR$filename") or 
				die "  [ Can't write config to $file ]\n"; 

		# Write out actual prefix in use, instead of the (maybe null) config prefix. 
		# Otherwise it may happen that the links will be rejected as "out" when read.
		# @tmp_prefix = @PREFIX;
	 	# $PREFIX[0] = $prefix;

		print FILE <<EOT; 
// Generated by $progname.pl Version $VERSION - Copyright 2000, Flavio Glock.
//
EOT
		foreach $var_name (@Config_Vars) {
			print FILE "//$var_name: \'", eval "\$$var_name", "\'\n";
		}
		foreach $var_name (@Config_Arrays) {
			foreach (0 .. eval "\$#$var_name") {
				#print "  [ eval: \$#$var_name -- \$", $var_name, "[$_] ]\n";
				print FILE "//$var_name: \'", eval ("\$" . $var_name . "[$_]"), "\'\n";
			}
		}
		print FILE "//\n";
	close (FILE);
	print "  [ CFG-SAVE: DONE $file ]\n" unless $QUIET;

	# restore vars
	#@PREFIX = @tmp_prefix;
}

sub make_filename {
	my ($url) = @_;
	my ($host, $port, $path, $query);	# $params, 

	$u1 = 		URI::URL->new($url);
	$host =		$u1->host;
	$port =		$u1->port;
	$path =		$u1->path;
	# $params = 	$u1->params;
	$query =	$u1->query;
	return &make_filename_from_parts($host, $port, $path, $query);
}


sub check_translation_file {
	my ($filename, $parent) = @_;
	my ($trans_filename, @a, $tr_str, $new_name);
	# do we have a $NAME_TRANSLATION_FILE ?
	$trans_filename = "$parent/$NAME_TRANSLATION_FILE";
	if (-s $trans_filename) {
		open (TRFILE, $trans_filename); 
			@a = <TRFILE>; 
		close (TRFILE);
		($tr_str) = grep { />\Q${filename}\E</ } @a;
		if ($tr_str) {
			# "<a href=$new_name>$filename</a><br>\n"
			($new_name) = $tr_str =~ /=(.*?)>/;
			print "  [ SHORTER-NAME: FOUND: $tr_str => $new_name ]\n" if $VERBOSE;
			return $new_name;
		}
	}
	return '';
}

sub log_translation_file {
	my ($filename, $new_name, $parent) = @_;
	my ($trans_filename);
	$trans_filename = "$parent/$NAME_TRANSLATION_FILE";
	&make_dir($trans_filename);
	open (TRFILE, ">>$trans_filename") or print "  [ ERR: WRITING $trans_filename - $^E ]\n"; 
		print TRFILE "<a href=$new_name>$filename</a><br>\n"; 
	close (TRFILE);
	print "  [ SHORTER-NAME: LOGGED: $new_name at $trans_filename ]\n" if $VERBOSE;
	return;
}

sub make_shorter_name {
	my ($filename, $parent) = @_;
	# ... md5 ... $NAME_LEN_MAX ...

	my ($new_name, $trans_filename, @a, $name, $extension, $maxname);
	my ($random_1, $random_2, $rnd);

	# do we have a name in $NAME_TRANSLATION_FILE ?
	if ($new_name = check_translation_file($filename, $parent)) {
		@_[0] = $new_name;
		return;
	}

	($name, $extension) = split('\.',$filename,2);
	if (length($extension) > 10) {
		# invalid extension? -- arbitrary limit
		print "  [ SHORTER-NAME: invalid extension: $extension ]\n" if $VERBOSE;
		($name, $extension) = ($filename,'');
	}
	$extension =~ tr/\//${INVALID_CHAR}/;	# in case this is a joined subdirectory name

	$maxname = $NAME_LEN_MAX - length($extension) - 1;
	$maxname = 8 if $maxname < 8;	# -- arbitrary limit, again

	if (length($name) <= $maxname) {
		# can't do any better?
		$new_name = $name;
		$new_name =~ tr/\//${INVALID_CHAR}/;	# in case this is a joined subdirectory name
		$new_name .= '.' . $extension if $extension;
	}
	else {
		print "  [ SHORTER-NAME: $name + $extension ]\n" if $VERBOSE;
		# 4 digits should be enough
		$digits = 4;					# 1000 .. 9999
		$random_1 = '1' . ('0' x ($digits - 1)); 	# 1 => 1000
		$random_2 = $random_1 . '0'; 			# 2 => 10000
		print " formula: int(rand($random_2 - $random_1)) + $random_1 \n";
		$maxname = $maxname - $digits + 1;
		$base_name = substr($name, 0, $maxname);
		$base_name =~ tr/\//${INVALID_CHAR}/;	# in case this is a joined subdirectory name
		# note: this way of verifying unique MAY be a problem in a multi-process environment
		do {
			$rnd = int(rand($random_2 - $random_1)) + $random_1;
			$new_name = $base_name . $rnd;
			$new_name .= '.' . $extension if $extension;
			# check for duplicate names
			print "  [ SHORTER-NAME: VERIFYING UNIQUE $new_name ]\n" if $VERBOSE;
		} while grep { /=$new_name>/ } @a;
	}
	# log the name-change
	log_translation_file($filename, $new_name, $parent) if $filename ne $new_name;
	@_[0] = $new_name;
}

sub make_filename_from_parts {
	my ($host, $port, $path, $query) = @_;
	my ($name);
	my ($depth1, @file_names, $parent);

	$name = $host;
	$name .= '_' . $port if ($port != 80) and ($name);

	$path =~ tr/\\/\//;		   	# \ => /
	$path =~ s/\/$/\/${INDEXFILE}/g;    	# final slash => "/$INDEXFILE"
	$path =~ s/\/\//\//g;			# // => /
	$path =~ s/\/[^\/]*?\/\.\.\//\//g;	# /aaa/xxx/../ => /aaa/
	$query =~ tr/ \\ \/ : \* \? \" < > \| /${INVALID_CHAR}/;	# invalid chars

	$name .= $path;
	$name =~ tr/ : \* \? \" < > \| /${INVALID_CHAR}/;

	$name .= $INVALID_CHAR . $query if $query;
	$name =~ s/\.$/\$/;		   	# final dot => invalid char

	# Win-NT charset:
	# 	allowed:	= & _ - space
	# 	not allowed:	\ / : * ? " < > |
	# Win-NT names with dots:
	#	allowed:	.* ..* ...*
	#			*.* *..* *...*
	#	not allowed:	. .. *.

 	print "  [ NAME: $name => (host) $host (path) $path (query) $query ]\n" if $VERBOSE;

	@file_names = split("\/", $name);
 	#print "  [ NAME: name_depth: $#file_names file_name: $file_names[-1] ]\n" if $VERBOSE;

	# up to 2 times dir depth reduction, by joining pairs of dir-names.

	if ($#file_names > $DIR_DEPTH_MAX) {
		$depth1 = $#file_names - 1;
		foreach (3 .. $depth1) {
			# print " process: $_ -- $#file_names -- $DIR_DEPTH_MAX \n";
			if (($#file_names > $DIR_DEPTH_MAX) and ($_ <= $#file_names)) {
				splice(@file_names, -$_, 2, 
					$file_names[-$_] . "/" . $file_names[1-$_]);
			}
		}
	}

	# again...

	if ($#file_names > $DIR_DEPTH_MAX) {
		$depth1 = $#file_names - 1;
		foreach (3 .. $depth1) {
			# print " process: $_ -- $#file_names -- $DIR_DEPTH_MAX \n";
			if (($#file_names > $DIR_DEPTH_MAX) and ($_ <= $#file_names)) {
				splice(@file_names, -$_, 2, 
					$file_names[-$_] . "/" . $file_names[1-$_]);
			}
		}
	}

	# check file/dir name length

	$parent = $BASE_DIR;
	foreach (0 .. $#file_names) {
		if ((length($file_names[$_]) > $NAME_LEN_MAX) or ($file_names[$_] =~ /\//)) {
			print "  [ NAME: CHANGE: $file_names[$_] at $parent ]\n";
			&make_shorter_name($file_names[$_], $parent);
			print "  [ NAME: NOW IS: $file_names[$_] ]\n";
		}
		$parent .= "/" unless $parent =~ /\/$/;
		$parent .= $file_names[$_];
	}

	$name = join("\/", @file_names);
 	print "  [ NAME: name_depth: $#file_names file_name: $file_names[-1] name: $name ]\n" if $VERBOSE;

	return $name;
}


sub make_dir {
	# o parametro para make_dir deve incluir a base
	my ($name) = @_;

	return if (-d $name);

	my (@a, $a, $b, $temp, $dest);
   	# cria o diretorio
	@a = split('/', $name);
	$a = '';
	foreach(0 .. $#a - 1) {
		$a .= $a[$_] . '/';
	}

	if (-d $a) {
		print "  [ DIR: $a ok ]\n" if $VERBOSE;
		return;
	}

	$b = $a; 
	$b =~ s/\/$//;
	if  (-e $b) {
			print "  [ MAKE-DIR: Dir $a tem arquivo com mesmo nome ]\n" if $VERBOSE;
			$temp = $b . $TMP_SUFFIX;
			print "  [ MAKE-DIR: MOVE: $b => $temp ]\n" if $VERBOSE;
			&my_rename ($b, $temp);
			mkdir $a, "-w";
			$dest = $b . '/' . $INDEXFILE;
			print "  [ MAKE-DIR: MOVE: $temp => $dest ]\n" if $VERBOSE;
			&my_rename ($temp, $dest);
	}
	$a = '';
	foreach(0 .. $#a - 1) {
			$a .= $a[$_] . '/';
			if (-d $a) {
				# print "  [ DIR: $a ok ]\n" if $VERBOSE;
			}
			else {
				print "  [ MAKE-DIR: $a ]\n" if $VERBOSE;
				mkdir $a, "-w";
			}
	}

}

sub my_unlink {
 	my ($source) = @_;
	if (-d $source) {
		print "  [ ERR: WILL NOT UNLINK DIRECTORY ]\n"; 
		return; 
	}
	if (-e $source) {
		unlink $source   or print "  [ ERR: UNLINK $source - $^E ]\n";  
	}
}

sub my_link {
	# note: link will COPY files on Windows
 	my ($source, $dest) = @_;
	return if $source eq $dest;
	unless (-e $source) {
		print "  [ LINK: CAN'T FIND $source ]\n" unless $QUIET;
		return;
	}
	if (-d $source) {
		print "  [ LINK: CAN'T LINK FROM DIRECTORY ]\n" unless $QUIET;
		return;
	}
	if (-e $dest) {
		print "  [ LINK: ALREADY EXISTS: $dest ]\n" unless $QUIET;
		return;
	}
	print "  [ LINK: $source to $dest ]\n" if $VERBOSE;
	link ($source, $dest);
}

sub my_create_empty {
 	my ($source) = @_;
	print "  [ CREATE-EMPTY: $source ]\n" if $VERBOSE;
	open (FILE, ">>$source");
		binmode FILE; print FILE "";
	close (FILE);
}

sub my_copy {
 	my ($source, $dest) = @_;
	return if $source eq $dest;
	unless (-e $source) {
		print "  [ COPY: CAN'T FIND $source ]\n";
		return;
	}
	if (-d $source) {
		print "  [ COPY: CAN'T COPY DIRECTORY ]\n";
		return;
	}
	&my_unlink ($dest);
	print "  [ COPY: $source, $dest ]\n" if $VERBOSE;
	open (FILE1, $source)  or print "  [ ERR: CAN'T READ $source - $^E ]\n"; 
	open (FILE2, ">$dest") or print "  [ ERR: CAN'T CREATE $dest - $^E ]\n"; 
		binmode FILE1; 
		binmode FILE2; 
	        local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
		while (<FILE1>) {
			print FILE2 $_; 
		}
	close (FILE2);
	close (FILE1);

	# (adapted from: UserAgent.pm)
	if (my $lm = (stat($source))[9] ) {
		# make sure the file has the same last modification time
		utime $lm, $lm, $dest;
	}
}

sub my_rename {
 	my ($source, $dest) = @_;
	return if $source eq $dest;
	unless (-e $source) {
		print "  [ RENAME: CAN'T FIND $source ]\n";
		return;
	}
	&my_unlink ($dest);
	unless (rename $source, $dest) {
		# print "  [ RENAME: CAN'T RENAME $source $dest - $^E ]\n";
		print "  [ RENAME: $source, $dest ]\n" if $VERBOSE;
		&my_copy ($source, $dest);	
		&my_unlink ($source);
		return;
	}
}

sub select_best_sample {
	my ($filename) = @_;
	my $msg = "  [ SELECT-SAMPLE: ERROR $filename$PART_SUFFIX";
	# escolhe a melhor tentativa

	# ensure that FILE is not in use

	#open (FILE, "$filename");
	#close (FILE);
	#open (FILE, "$filename$PART_SUFFIX");
	#close (FILE);
	#open (FILE, "$filename$PART_SUFFIX-1");
	#close (FILE);

	if (-s "$filename" > 0) {
		print "  [ SELECT-SAMPLE: EXISTS: $filename ]\n" if $VERBOSE;
		# ja existe o arquivo pronto - apaga os outros
		&my_unlink ("$filename$PART_SUFFIX"); 
		&my_unlink ("$filename$PART_SUFFIX-1");
		return;
	}
	if (! (-e "$filename$PART_SUFFIX-1")) {
		print "  [ SELECT-SAMPLE: KEEP: $filename$PART_SUFFIX-1 ]\n" if $VERBOSE;
		# nao existe outra alternativa
		return;
	}
	if (! (-e "$filename$PART_SUFFIX")) {
		print "  [ SELECT-SAMPLE: KEEP: $filename$PART_SUFFIX ]\n" if $VERBOSE;
		# nao existe outra alternativa
		&my_rename ("$filename$PART_SUFFIX-1", "$filename$PART_SUFFIX");
		return;
	}
	# existem $PART_SUFFIX e $PART_SUFFIX-1 -- deve escolher o maior
	if (+(-s "$filename$PART_SUFFIX") > +(-s "$filename$PART_SUFFIX-1")) {
		print "  [ SELECT-SAMPLE: BIGGER: $filename$PART_SUFFIX ]\n" if $VERBOSE;
		&my_unlink ("$filename$PART_SUFFIX-1");
		return;
	}
	# $PART_SUFFIX-1 is bigger -- delete $PART_SUFFIX and rename $PART_SUFFIX-1
	print "  [ SELECT-SAMPLE: BIGGER: $filename$PART_SUFFIX-1 ]\n" if $VERBOSE;
	&my_rename ("$filename$PART_SUFFIX-1", "$filename$PART_SUFFIX");
}

sub download_callback { 
	my($data, $response, $protocol) = @_; 
	# "$filename", "$num_callback" are global
	$num_callback++;

	# The callback function is called with 3 arguments: the data received this time, a
	# reference to the response object and a reference to the protocol object.

	# testa se a resposta e' do tipo 206 Partial Content
	# Content-Length: 10000
	# Content-Range: bytes 10329-20328/20329

	if ($num_callback == 1) {
		if ($response->code == 206) { 
			($content_begin) = $response->header("Content-Range") =~ /bytes\s+(\d+)-/;
			#print "  [ BEGIN = ", $content_begin, " ] \n";
			if (-s "$filename$PART_SUFFIX" != $content_begin) { die "Wrong range"; }
		} else {
			# Nao aceita resume
			#die "Nao aceita resume"; 
			# circula os arquivos de tentativas - depois deve escolher a melhor
			&select_best_sample($filename);
			&my_rename ("$filename$PART_SUFFIX", "$filename$PART_SUFFIX-1");
			# normal download to file
			print "  [ NO-RESUME: Novo request ]\n" if $VERBOSE;
			&my_create_empty ("$filename$PART_SUFFIX");
		}
	}

	open(FILE, ">>$filename$PART_SUFFIX") or 
			die "Cannot write to $filename$PART_SUFFIX";
        	binmode(FILE);
	        local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
		print FILE $data;
	close(FILE);

	#print "  [ CALLBACK = ", $num_callback, " ] \n";
	#print "  [ RESPONSE->CODE = ", $response->code, " ] \n";
	#print "  [ RESPONSE->Content-Range = ", $response->header("Content-Range"), " ] \n";
	#print "  [ RESPONSE->HEADER = ", $response->as_string, " ] \n";
}



sub download {
	my ($url, $referer, $nivel) = @_;
	$mime_text_html = 0;
	$Content_Type = '';
	$u1 = $url;
	# cuida para ficar neste host
	# $OUT_DEPTH == 0  - nao faz download externo
	# $OUT_DEPTH == 1  - faz download mas nao segue (nivel zero)
	unless (grep { $url =~ /$_/ } @PREFIX) {
		print "  [ OUT ", join(",",@PREFIX), " DEPTH:$nivel OUT-DEPTH:$OUT_DEPTH ]\n" if $VERBOSE;
		return if $OUT_DEPTH < 1;
		$nivel = $OUT_DEPTH - 1 if $nivel >= $OUT_DEPTH;
		return if $nivel < 0;
		print "  [ OUT: DEPTH => $nivel ]\n" if $VERBOSE;
	}
	# controle do que ja foi visitado
	$meio1 = $#processed / 3;
	$meio2 = $meio1 + $meio1;
	foreach (0 .. $meio1, $meio2 .. $#processed, +($meio1 + 1) .. +($meio2 - 1)) {
		if ($processed[$_] eq $url) {
			print "  [ DID ]\n" if $VERBOSE;
			return;
		}
	}
	push @processed, $url;
	$name = &make_filename($url);
	$filename = "$BASE_DIR$name";	# $filename is global

	if (-e "$filename$NOT_FOUND_SUFFIX") {
		print "  [ NOT-FOUND: ja existe $filename$NOT_FOUND_SUFFIX ]\n" if $VERBOSE;
		return;
	}

	$mtime = 0;
	if (-e $filename) {
		if (-d $filename) {
			print "  [ DIR EXISTS: $filename ]\n" if $VERBOSE;
			$filename .= '/' . $INDEXFILE;
			print "  [ CREATE FILE: $filename ]\n" if $VERBOSE;
			unless ($MIRROR) { 
				if (-s $filename) {
					# URL should have ending "/"
					($path, $query) = split('\?', $url, 2);
					$url = $path . '/' . $query if ! ($path =~ /\/$/);
					goto DOWNLOAD_OK;
				}
			}
		} elsif (-s $filename) {
			print "  [ FILE EXISTS: $filename ]\n" if $VERBOSE;
			unless ($MIRROR) { 
				goto DOWNLOAD_OK;
			}
		}
		$mtime = (stat($filename))[9];
	}

	&make_dir($name);
	# print "Download: $url\n";

	if ($DUMP and ($nivel < 1) and ($dump_nivel_zero)) {
		print "  [$nivel => DUMP]\n" if $VERBOSE;
		push_list (\@dump, $url, $referer, $nivel);
		return;
	}

    	if ($SLEEP) {
		&my_sleep($SLEEP);
	}

	# GET:
	print "  [ GET: $u1 ]\n" unless $QUIET;
	my $req = HTTP::Request->new(GET => $url);
	$req->referer($referer . '');
	# declare preference for "html" directory listings, if "ftp"
	$req->header('Accept' => 'text/html;q=1.0,*/*;q=0.6');

	$req->authorization_basic(split (/:/, $AUTH)) if ($AUTH);

	if ($mtime) {
		print "  [ If-Modified-Since: ", HTTP::Date::time2str($mtime), " ]\n" if $VERBOSE;
		$req->header('If-Modified-Since' => HTTP::Date::time2str($mtime));
	}

	$download_success = 1;

	# RESUME:
	# The first-byte-pos value in a byte-range-spec gives the byte-offset
   	# of the first byte in a range. The last-byte-pos value gives the
   	# byte-offset of the last byte in the range; that is, the byte
   	# positions specified are inclusive. Byte offsets start at zero.
	# Range: bytes=9500-
	$filesize = 0 + (-s "$filename$PART_SUFFIX");
	if ($filesize != 0) 
	{
		&select_best_sample($filename);
		$filesize = 0 + (-s "$filename$PART_SUFFIX");
		$num_callback = 0;
		print "  [ RESUME: from byte $filesize ]\n" if $VERBOSE;
		#$file_end = $filesize + 10000;
		#$req->push_header("Range" => "bytes=$filesize-$file_end");
		$req->push_header("Range" => "bytes=$filesize-");
		print "  [ REQUEST = ", $req->as_string, " ] \n" if $VERBOSE;
		# chama o callback
		$res = $ua->request($req, \&download_callback, 65536); 	# 65536); 
		if ($res->header("X-Died")) {
			# circula os arquivos de tentativas - depois deve escolher a melhor
			&select_best_sample($filename);
		} 
		# - look at the 3rd parameter on "206" 
		# (when available -- otherwise it may be 500 Timeout),
		# Content-Length: 637055 --> if "206" this is "chunk" size
		# Content-Range: bytes 1449076-2086130/2086131 --> THIS is file size
		$content_range = $res->header("Content-Range");
		if (($res->code == 206) and $content_range) {
			($content_begin, $content_end, $content_size) = $content_range =~ /bytes\s+(\d+)-(\d+)\/(\d+)/;
			$file_size = -s "$filename$PART_SUFFIX";
			$content_difference = $content_size - $file_size;
			if ($content_difference > 0) { 
				$download_success = 0;	# not ready yet
				print "  [ CONTENT: MISSING: $content_difference/$content_size BYTES ] \n" if $VERBOSE;
			}
			else {
				print "  [ CONTENT: OK: $file_size/$content_size BYTES ] \n" if $VERBOSE;
			}
		}
	}
	else {
		# normal download to file
		$res = $ua->request($req, "$filename$PART_SUFFIX");
	}

	# DOWNLOAD FINISHED OR ABORTED

	unless ($download_success and $res->is_success) {
		print "  [ RESPONSE: ERROR <<\n", $res->as_string, "    >> RESPONSE ]\n" if $VERBOSE;
		$msg = $res->status_line;
		if ($msg =~ /304/) {
			print "  [ OK: 304 NOT MODIFIED ]\n" unless $QUIET;
		}
		if (($msg =~ /404/) and ($url =~ /(.*)${INDEXFILE}$/)) {
			# looks like we are re-processing the cache...
			# try to find out original URL
			print "  [ OOPS: Are we re-processing the cache? $1 => LATER ]\n" unless $QUIET;
			push_list (\@retry, $1, $referer, $nivel);
		}
		elsif (($msg =~ /404/) and (! $RETRY_404)) {
			print "  [ ERROR $msg => CANCEL ]\n" unless $QUIET;
			if (-e "$filename$PART_SUFFIX") {
				# cria arquivo not-found
				&my_rename ("$filename$PART_SUFFIX", "$filename$NOT_FOUND_SUFFIX");
			}
			elsif (-e "$filename") {
				&my_rename ("$filename", "$filename$NOT_FOUND_SUFFIX");
			}
			elsif (-e "$filename$NOT_FOUND_SUFFIX") {
			}
			else {
				&my_create_empty("$filename$NOT_FOUND_SUFFIX");
			}
		# } 
		# elsif ($DUMP) {
		#	print "  [ ERROR $msg => DUMP ]\n";
		#	&insert_url_2 ($url, $referer, 0);	# marca como nivel zero
		} else {
			print "  [ ERROR $msg => LATER ]\n" unless $QUIET;
			push_list (\@retry, $url, $referer, $nivel);
			# print "    $retry -- push ", join(",", @retry) , " ($url, $referer, $nivel) \n";
		}
		return;
	} # end: error on download

	# DOWNLOAD FINISHED AND CORRECT

		print "  [ OK: ", $res->status_line, " ]\n" if $VERBOSE;
		&my_rename ("$filename$PART_SUFFIX", "$filename");
		&my_unlink ("$filename$PART_SUFFIX-1");

		$num_docs++;

		print "  [ RESPONSE <<\n", $res->as_string, "    >> RESPONSE ]\n" if $VERBOSE;
		#HTTP/1.1 200 OK
		#Connection: close
		#Date: Sat, 23 Sep 2000 08:52:22 GMT
		#Server: Apache/1.3.6 (Unix)
		#Content-Type: text/html
		#Content-Type: image/jpeg
		#Content-Location: http://www.cade.com 
		#Accept-Ranges: bytes
		#Content-Length: 74623
		#Last-Modified: Mon, 17 Apr 2000 18:13:11 GMT

		$Content_Type = $res->content_type;

		# (from: UserAgent.pm)
		if (my $lm = $res->last_modified) {
			# make sure the file has the same last modification time
			utime $lm, $lm, $filename;
		}

	# REDIRECT:

		#     Location:         indica que um novo documento deve ser obtido
		#     Content-Location: indica o lugar onde este documento esta armazenado
		#     Content-Base:     indica o diretorio onde este documento esta armazenado
		#     $res->base        guess directory location

		@urls = ($url);		# store the url variants
		print "  [     URL: $url ]\n";

		# create a root-relative url name for relocating ( /... )
		#$url_object = URI::URL->new($url);

		#$relative_url = $url_object->path . " " . 
		#		$url_object->params . " " . 
		#		$url_object->query;
		#print "  [ RELATIVE-URL: $relative_url ]\n";

		$content_base = $res->header("Content-Base");
		unless ($content_base) {
			# try to guess base
			$base = $res->base;
			$u1 = 	URI::URL->new_abs($base,$url);
			$base = $u1;
			$base =~ s/\?.*//;  # remove query
			print "  [ BASE_PATH: $base ]\n" if $VERBOSE;
			$res->header( 'Content_Base' => "$base");   
			$content_base = $res->header("Content-Base");
		}
		#if ($content_base) {
		#	$dir_base = &make_filename($content_base);
		#	&make_dir($dir_base);  			     # should do this LATER!
		#}

		# check if url directory changed
		#$base_filename = &make_filename($base);

		# find out file name with query, without directory
		$u1 = 		URI::URL->new($url);
		$path =		$u1->path;
		$path =~ 	s|^(.*)\/||g;   # remove directory
		#($url_base) =	$u1 =~ /(.*)$path/;
		#print "  [ GET PATH: $url_base $path ]\n" if $VERBOSE;

		$url_no_query = $url;
		$url_no_query =~ s/\?.*//;

		$path1 = $path;
		$path2 = '';
		$path1 .= '?' . $u1->query if $u1->query;
		$path2 .= '?' . $u1->query if $u1->query;

		#print "  [ PATH 1:  $content_base$path1 ]\n" if $VERBOSE;
		#print "  [ PATH 2:  $content_base$path2 ]\n" if $VERBOSE;

		if ($content_base eq ($url_no_query . "/")) {
			$new_url = "$content_base$path2";
		}
		else {
			$new_url = "$content_base$path2";
		}
		print "  [ NEW URL:  $new_url ]\n" if $VERBOSE and ($new_url ne $url);
		push @urls, $new_url if $new_url ne $url;

		$location = $res->header("Location");
		if ($location) {
			if ($content_base) {
		    		$u1 = URI::URL->new_abs($location, $content_base);
			} 
			else {
		    		$u1 = URI::URL->new_abs($location, $referer);
			}
			&insert_url ($u1, $url, $nivel  - 1);
		} # fim: Location

		$content_location = $res->header("Content-Location");
		if ($content_location) {
			if ($content_base) {
		    		$u1 = URI::URL->new_abs($content_location, $content_base);
			} 
			else {
		    		$u1 = URI::URL->new_abs($content_location, $referer);
			}
			push @urls, $u1 if ($u1 ne $url) and ($u1 ne $new_url);
		} # fim: Content-Location


	# SAVE REDIRECT

		if ($#urls > 0) {
			# more than 1 filename option
			print "  [ REDIRECT: ", join(",", @urls), " ]\n" if $VERBOSE;
			# last option is probably better
			# make it the referer for our links
			$url = $urls[-1];

		    	$new_file_location = &make_filename($urls[-1]);
		    	$new_file_location = "$BASE_DIR$new_file_location";
			print "  [ FILE-LOCATION: $new_file_location ]\n" if $VERBOSE;
			&make_dir ($new_file_location);
			if (-e $new_file_location) {
				print "  [ FILE-LOCATION: EXISTS ]\n" if $VERBOSE;
			}
			else {
				&my_rename($filename, $new_file_location);
			}
			$filename = $new_file_location;
		}

	# MAKE ALTERNATE FILENAMES

		@filenames = ($filename);
		foreach (0 .. ($#urls - 1)) {
		    	$new_file_location = &make_filename($urls[$_]);
		    	$new_file_location = "$BASE_DIR$new_file_location";
			push @filenames, $new_file_location;
			# print "  [ ALT-FILE-LOCATION: $urls[$_] => $new_file_location ]\n" if $VERBOSE;
		}

		# CHECK SUFFIX (JPG/GIF/HTM)
		# $suffix = "";
		if ($MEDIAEXT and $Content_Type) {
			@suffix = media_suffix($Content_Type);
			print "  [ Content-Type: $Content_Type = @suffix ]\n" if $VERBOSE;
			unless (grep { $filename =~ /\.$_$/i } @suffix) {
				print "  [ WARNING: Missing Suffix: $filename ]\n" if $VERBOSE;
				$suffix = @suffix[0];
				push @filenames, $filename . "." . $suffix;
			}
		}

	# link other names to main name

		foreach (0 .. $#filenames) {
			print "  [ ALT-FILE-LOCATION: $filenames[$_] ]\n" if $VERBOSE;
			my_link ($filename, $filenames[$_]);
		}

	# BEGIN CHECKING CONTENT

		if ($Content_Type eq "text/ftp-dir-listing") {
			print "  [ FTP-DIR: Content-Type: text/ftp-dir-listing ]\n" if $VERBOSE;

			# make dir (if not done)
			$content_location = $res->header("Content-Location");
			$url_path = $url;
			if ((! $content_location) and (! ($url_path =~ /\/$/))) {
				$url_path = $url_path . '/' . $INDEXFILE;
				# $url = $url_path;
				$res->header("Content-Location", $url_path);
				print "  [ NEW URL-PATH: ", $url_path, " ]\n";
			}

			# make "href"s

		}

		if ($Content_Type eq "text/html") {
			print "  [ HTML: Content-Type: text/html ]\n" if $VERBOSE;
			$mime_text_html = 1;
		} else {
			$mime_text_html = 0;
		}


DOWNLOAD_OK:
	# arriving here from FILE: (cache) or from HTTP:

	# haven't we run out of depth? and we don't need to read the file?
	return if ($nivel < 1) and ! $MAKEREL;

	# is it HTML or related?
	return if ! ($mime_text_html or ($filename =~ /\..?htm.?$/i));
	return if eval "\$filename =~ $default_exclude";

	# ok, it is HTML - let's read it back
	open (FILE, "$filename"); 
		binmode(FILE);
		@a = <FILE>; 
	close (FILE);
	chomp(@a); $_ = join(' ', @a);

	$Full_Text = $_;

	print "  [ CONTENTS <<\n$_\n    >> CONTENTS ]\n" if $VERBOSE;
	my @links1 = ();

	# help identifying delimiters
	@tags = /(<.*?>)/g;
	#print join("\n", @tags);

	foreach(@tags) {

			# do not consider comments <! > unless they are javascript
			# s/<!.*?>//;

			# <BODY BACKGROUND="..
			push @links1, /<.{0,100}?background\s{0,100}?=\s{0,100}?\"?(.{0,100}?)[">\s]/ig;
		
			# a href, area href, ref href, span href
			push @links1, /<.{0,100}?href\s{0,100}?=\s{0,100}?\"?(.{0,100}?)[">\s]/ig;
		
			# image src, frame src, script src, embed src 
			push @links1, /<.{0,100}?src\s{0,100}?=\s{0,100}?\"?(.{0,100}?)[">\s]/ig;
		
			# javascript: window.open
			# window.open('http://www5.via-rs.com.br/mapa/mapa_n.php3','...
			push @links1, /window\.open\s{0,100}?\(\s{0,100}?\'(.{0,100}?)\'/ig;

			# javascript: jump()
			#  JAVASCRIPT:jump(&quot;http://www.phy.ntnu.edu.tw/java/index.html&quot; )
			push @links1, /&quot;(http\:\/\/.{0,100}?)&quot;/ig;
			push @links1, /\"(http\:\/\/.{0,100}?)\"/ig;
			push @links1, /\'(http\:\/\/.{0,100}?)\'/ig;
			# JAVESCRIPT:jump('color/color_e.html')
			push @links1, /\"(.{0,100}?\.html)\"/ig;
			push @links1, /\'(.{0,100}?\.html)\'/ig;

			push @links1, /\"(.{0,100}?\.htm)\"/ig;
			push @links1, /\'(.{0,100}?\.htm)\'/ig;

			# java: <OPTION  VALUE="http://www.gruposinos.com.br/abc">	     
			push @links1, /<option.*?value\s{0,100}?=\s{0,100}?\"?(http\:\/\/.{0,100}?)[">\s]/ig;
		
			# refresh
			push @links1, /<meta.{10,20}?refresh.{10,20}?url=(.{0,100}?)[">\s]/ig;

			# span class -- correction: this is not java, it is css
			# <span class="plntxt"> <b class="xxx">
	
			# applet
			@a = /<applet(.*?)>/ig;
			# <applet archive="..." code="..." ...
			# <applet codebase="..." code="..." ...
			# <applet code="rc.class" width=460  height=300>     
			foreach (@a) {
				if (/archive=\s{0,100}\"{0,1}(.{0,100}?)[">\s]/i) {
					print "  [ APPLET: archive==$1 ]\n" if $VERBOSE;
					$archive = $1;
				} else {
					$archive = "";
				}
				if (/code=\s{0,100}\"{0,1}(.{0,100}?)[">\s]/i) {
					print "  [ APPLET: code==$1 ]\n" if $VERBOSE;
					$code =  $1;
				} else { 
					print "  [ APPLET: code==null ]\n" if $VERBOSE;
					$code = ""; 
				}
				if (/codebase=\s{0,100}\"{0,1}(.{0,100}?)[">\s]/i) {  
					$codebase = $1; 
				} else { 
					$codebase = ""; 
				}
				$applet = "$codebase$code";
				push @links1, $archive if $archive;
				push @links1, "$codebase$archive" if $archive and $codebase;
				print "  [ APPLET: $_ => $codebase$code ]\n" if $VERBOSE;
				push @links1, $applet;
				push @links1, $applet . ".class" if !  ($applet =~ /\.class$/);
			} # applets
	} # tags

	# retira repeticoes e links invalidos
	@links1 = sort @links1;
	$prev = '';
	foreach (@links1) {
		# nao mailto:, file:, javascript: ou "javescript:"
		# nao vazio ou com espacos, nao repetido dentro da pagina
		#print "  [ TEST: $_ == $prev ]\n";
		$_  =~ s/#.*//;   # retira o fragmento antes de comparar
		$_  =~ s/[';\{\}\[\]]//g;     # retira o lixo javascript antes de comparar
		if ($_ ne $prev) {
		    	$prev = $_;
			if (    ($_) and
				(! /^mailto:/i) and 
				(! /^javascript:/i) and 
				(! /^'javascript:/i) and 
				(! /^javescript:/i) and 
				(! /a href\=/i) and 
				(! /\s/i) and 
				(! /^file:\/\//i)) {
				# valid link
				print "  [ LINK: $_ ]\n" if $VERBOSE;
			}
			else { 
				print "  [ LINK: INVALID $_ ]\n" if $VERBOSE;
				$_ = undef;
			}
		}
		else { $_ = undef }
	}

	# monta a estrutura @links = ($url, $referer,  $nivel, ...)
	# filter links for MAKEREL
	# $url_object = URI::URL->new($url);

	$url_filename = &make_filename($url); 
	$uri_filename = "file://" . $url_filename;

	$count = 0;
	foreach (@links1) {
		if ($_) {
			$prev = $_;

			&insert_url ($_ . '', $url . '', $nivel  - 1);

			if ($MAKEREL and $mime_text_html) {
				# make links "local"
				$u1 = URI::URL->new_abs($prev, $url);
				$new_filename = &make_filename($u1); 
				$new_file_uri = URI::URL->new("file://" . $new_filename);
				$rel_filename = $new_file_uri->rel($uri_filename);

				if ($rel_filename =~ /file:\/\//) {
					# not ready yet...
					print "  [ REL: NOT SAME HOST: ", $u1->host, " ]\n" if $VERBOSE;
					# put enough "../../../" on it
					($base_filename) = $filename =~ /${BASE_DIR}(.*)/;
					$file_depth = $base_filename =~ tr|\/|\/|;
					print "  [ FILENAME: $base_filename -- $filename $file_depth ]\n" if $VERBOSE;
					$rel_filename = ("../" x $file_depth) . $new_filename;
				}

				$count+= $Full_Text =~ s/([=\"\s])\Q$prev\E([\"\s\>])/$1$rel_filename$2/g;
				print "  [ REL: $count: $rel_filename -- $prev ]\n" if $VERBOSE;
			}
		}
	}

	if ($count) {
		print "  [ REL: COUNT $count << $Full_Text >> REL ]\n" if $VERBOSE;
		# make backup
		my_copy($filename, $filename . $BACKUP_SUFFIX);
		# write file back to disk
		$lm = (stat($filename))[9];	# keep last modification time
		open (FILE, ">$filename"); 
			binmode(FILE);
			print FILE $Full_Text; 
		close (FILE);
		utime $lm, $lm, $filename if $lm;
	}      

} # end: download

sub insert_url {
	my ($url, $referer, $nivel) = @_;
	my ($tmp, $tmp2);

	return if $nivel < 0;

	# make absolute URL from referer, without fragment:
	$_ = $url;
	#print "LINKS $#links ++ $_  ++";
	$_ =~ s/#.*//;   # retira o fragmento
	$url = URI::URL->new_abs($_, $referer);

	# resolve erros de javascript misturado com html
	$str_url = $url;
	if ($str_url =~ s/[';]//g) {
		print "  [ ERR JAVASCRIPT: ", $url, " => ", $str_url, " ]\n" if $VERBOSE;
		$url->new($str_url);
	}	

	# resolve erro: http://host/../file esta sendo gravado em ./host/../file => ./file
	my $path = $url->path;
	#print "  [ PATH: ", $url->path, " ]\n" if $path =~ /\.\./;
	# /../ => /
	if ($path =~ s/^\/\.\.\//\//g) {
		print "  [ ERR PATH: ", $url->path, " => ", $path, " ]\n" if $VERBOSE;
		$url->path($path);
	}	

	# cuida para ficar neste host
	# $OUT_DEPTH == 0  - nao faz download externo
	# $OUT_DEPTH >= 1  - deixa para a rotina de download decidir
	if ( ($OUT_DEPTH < 1) and not (grep { $url =~ /$_/ } @PREFIX) ) {
		print "  [ OUT: $url ]\n" if $VERBOSE;
		return;
	}

	# pre-processador: EXCLUDE, LOOP, SUBST
	$_ = $url;
	print "  [ PREPROCESSOR: URL => $url ]\n" if $VERBOSE;
	if (eval $SUBST) {
		print "  [ SUBST $SUBST => $_ ]\n" if $VERBOSE;
		$url = $_;
	}
	foreach $exclude (@EXCLUDE) {
		if ( eval $exclude ) {
			print "  [ EXCLUDE $exclude ]\n" if $VERBOSE;
			return;
		}
	}
	if ($loop[0] and (/$loop[0]/)) {
		$tmp = $_;
		print "  [ LOOP: BEGIN $loop[0] : $loop[1] = ", join(",", eval $loop[1]), " ]\n" if $VERBOSE;
		foreach (eval $loop[1]) {
			$tmp2 = $tmp;
			$tmp2 =~ s/$loop[0]/$_/g;
			print "  [ LOOP: $tmp2 ]\n" if $VERBOSE;
			&insert_url_2 ($tmp2, $referer, $nivel);
		}
		print "  [ LOOP: END ]\n" if $VERBOSE;
	} else {
		&insert_url_2 ($url, $referer, $nivel);
	}
} # fim: insert_url

sub insert_url_2 {
	# "armazenador" geral de links/dump
	my ($url, $referer, $nivel) = @_;

	#$teste = eval "\$url =~ $default_exclude";
	#print " ++ teste [$teste] $url\n";
	print "  [ PUSH: $url $nivel ]\n" if $VERBOSE;

	if (! $DUMP) {
		push_list (\@links, $url, $referer, $nivel);
	} else {
		if (( ! $SLAVE) and (eval "\$url =~ $default_exclude")) {
			print "  [BIN => DUMP]\n" if $VERBOSE;
			push_list (\@dump, $url, $referer, $nivel);
		} else {
			push_list (\@links, $url, $referer, $nivel);
		}
	}
}

sub push_list {
	# "armazenador" - $arrayp == \@array
	my ($arrayp, $url, $referer, $nivel) = @_;
	my ($ini, $fim);
	$ini_index = 0;					# begin of first record
	$fim_index = $#$arrayp - $LIST_SIZE + 1; 	# begin of last record
	# testa o inicio e o final da lista, e depois o meio
	while ($fim_index >= $ini_index) {
		# print " $$arrayp=", $$arrayp[$index], "--", $$arrayp[$index+1], " ";
		if ( ($url eq $$arrayp[$ini_index]) or
		     ($url eq $$arrayp[$fim_index]) ) {
			print "  [ PUSH: repetido ]\n" if $VERBOSE;
			return;
		}
		$fim_index -= $LIST_SIZE;
		$ini_index += $LIST_SIZE;
	}
	push @$arrayp,  ($url, $referer, $nivel);
}

sub shift_list {
	# complementa push_list retirando o primeiro elemento da lista
	# $arrayp == \@array
	my ($arrayp) = @_;
	$url =     shift @$arrayp;
	$referer = shift @$arrayp;
	$nivel =   shift @$arrayp;
	print "  [ SHIFT: $url ]\n" if $VERBOSE;

	return ($url, $referer, $nivel);
}

sub not_implemented {
	my ($var) = @_;
	return if $var < 1;	# [0] == nome da funcao
	print "  [ CFG: $var NOT IMPLEMENTED ]\n" if $VERBOSE;
}

sub print_version {
	print <<EOT;
This is $progname.pl Version $VERSION

Copyright 2000, Flavio Glock.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
EOT
	exit 0;
}

sub usage {
	$show_subst = $SUBST;
	$show_subst =~ s/\\/\\\\/g;
	print <<EOT;
Usage: 
  Do-everything at once:        
    $progname.pl [options] <URL>
  Save work to finish later:    
    $progname.pl [options] --dump="dump-file" <URL>
  Finish saved download:        
    $progname.pl [options] "download-list-file"
  Network mode (client/slave)
  - Clients:      
    $progname.pl [options] --dump="dump-file" <URL>
  - Slaves (will wait until there is something to do): 
    $progname.pl [options] --slave

Very basic:
  --version         Print version number ($VERSION) and quit
  --verbose         More output
  --quiet           No output
  --help            This page
  --cfg-save        Save configuration to file "$CFG_FILE"
  --base-dir=DIR    Place to load/save files (default is "$BASE_DIR")

Download options are:
  --sleep=SECS      Sleep between gets, ie. go slowly (default is $SLEEP)
  --prefix=PREFIX   Limit URLs to those which begin with PREFIX (default is URL)
                    Multiple --prefix are allowed
  --depth=N         Maximum depth to traverse (default is $DEPTH)
  --out-depth=N     Maximum depth to traverse outside of PREFIX (default is $OUT_DEPTH)
  --referer=URI     Set initial referer header (default is "$REFERER")
  --limit=N         A limit on the number documents to get (default is $MAX_DOCS)
  --retry=N         Maximum number of retrys (default is $RETRY_MAX)
  --timeout=SECS    Timeout value - increases on retrys (default is $TIMEOUT)
  --agent=AGENT     User agent name (default is "$AGENT")
  --mirror          Checks all existing files for updates (default is --nomirror)
  --mediaext        Creates a file link, guessing the media type extension (.jpg, .gif)
                    (Windows perl makes a file copy) (default is --nomediaext)
  --makerel         Make Relative links. Links in pages will work in the
                    local computer.
  --auth=USER:PASS  Set authentication credentials
  --cookies=FILE    Set up a cookies file (default is no cookies)
  --name-len-max    Limit filename size (default is $NAME_LEN_MAX)
  --dir-depth-max   Limit directory depth (default is $DIR_DEPTH_MAX)

Multi-process control:
  --slave           Wait until a download-list file is created (be a slave)
  --stop            Stop slave
  --restart         Stop and restart slave

Not implemented yet but won't generate fatal errors:
  --hier            Download into hierarchy (not all files into cwd)
  --iis             Workaround IIS 2.0 bug by sending "Accept: */*" MIME
                    header; translates backslashes (\) to forward slashes (/)
  --keepext=type    Keep file extension for MIME types (comma-separated list)
  --nospace         Translate spaces URLs (not #fragments) to underscores (_)
  --tolower         Translate all URLs to lowercase (useful with IIS servers)

Other options: (to-be better explained)
  --indexfile=FILE  Index file in a directory (default is "$INDEXFILE")
  --part-suffix=.SUFFIX (default is "$PART_SUFFIX") (example: ".Getright" ".PART")
  --dump=FILE       (default is "$DUMP") make download-list file, 
                    to be used later
  --dump-max=N      (default is $DUMP_MAX) number of links per download-list file
  --invalid-char=C  (default is "$INVALID_CHAR")
  --exclude=/REGEXP/i (default is "@EXCLUDE") Don't download matching URLs
                    Multiple --exclude are allowed
  --loop=REGEXP:INITIAL..FINAL (default is "$LOOP") (eg: xx:a,b,c  xx:'01'..'10')
  --subst=s/REGEXP/VALUE/i (default is "$show_subst") (obs: "\" deve ser escrito "\\")
  --404-retry       will retry on error 404 Not Found (default). 
  --no404-retry     creates an empty file on error 404 Not Found.
EOT
	exit 0;
}

1;

