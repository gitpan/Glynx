#!/usr/bin/perl
# Copyright (c) 2000 Flavio Glock <fglock@pucrs.br>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# This program was based on examples in the Perl distribution.
# 
# If you use it/like it, send a postcard to the author. 
# Find the latest version in: http://www.pucrs.br/flavio

use Cwd 		qw(abs_path);
use Getopt::Long;
use LWP::UserAgent;
use URI::URL;
use URI::Heuristic 	qw(uf_uristr);

my $VERSION = "1.022";


=head1 NAME

Glynx - a download manager. 

Download from http://www.ipct.pucrs.br/flavio/glynx/glynx-latest.pl

=head1 DESCRIPTION

Glynx makes a local image of a selected part of the internet.

It can be used to make download lists to be used with other download managers, making
a distributed download process.

It currently supports resume, retry, referer, user-agent, java, frames, distributed
download (see C<--slave>, C<--stop>, C<--restart>).

It partially supports redirect, javascript, multimedia, authentication

It does not support mirroring (checking file dates), forms

It has not been tested with "https" yet.

It should be better tested with "ftp". 

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

How to make a default configuration:

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

Very basic:

  --version         Print version number ($VERSION) and quit
  --verbose         More output
  --quiet           No output
  --help            Help page
  --cfg-save        Save configuration to file "$CFG_FILE"
  --base-dir=DIR    Place to load/save files (default is "$BASE_DIR")

Download options are:

  --sleep=SECS      Sleep between gets, ie. go slowly (default is $SLEEP)
  --prefix=PREFIX   Limit URLs to those which begin with PREFIX (default is URL base)
                    Multiple "--prefix" are allowed.
  --depth=N         Maximum depth to traverse (default is $DEPTH)
  --out-depth=N     Maximum depth to traverse outside of PREFIX (default is $OUT_DEPTH)
  --referer=URI     Set initial referer header (default is "$REFERER")
  --limit=N         A limit on the number documents to get (default is $MAX_DOCS)
  --retry=N         Maximum number of retrys (default is $RETRY_MAX)
  --timeout=SECS    Timeout value - increases on retrys (default is $TIMEOUT)
  --agent=AGENT     User agent name (default is "$AGENT")

Multi-process control:

  --slave           Wait until a download-list file is created (be a slave)
  --stop            Stop slave
  --restart         Stop and restart slave

Not implemented yet but won't generate fatal errors (compatibility with lwp-rget):

  --auth=USER:PASS  Set authentication credentials for web site
  --hier            Download into hierarchy (not all files into cwd)
  --iis             Workaround IIS 2.0 bug by sending "Accept: */*" MIME
                    header; translates backslashes (\) to forward slashes (/)
  --keepext=type    Keep file extension for MIME types (comma-separated list)
  --nospace         Translate spaces URLs (not #fragments) to underscores (_)
  --tolower         Translate all URLs to lowercase (useful with IIS servers)

Other options: (to-be better explained)

  --indexfile=FILE  Index file in a directory (default is "$INDEXFILE")
  --part-suffix=.SUFFIX (default is "$PART_SUFFIX") (eg: ".Getright" ".PART")
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

=head1 TO-DO

More command-line compatibility with lwp-rget

Graphical user interface

=head1 README

Glynx - a download manager. 

Installation:

    Windows:
	- unzip to a directory, such as c:\glynx or even c:\temp
	- this is a DOS script, it will not work properly if you double click it.
	However, you can put it in the startup directory in "slave mode" 
	making a link with the --slave parameter. Then open another DOS window
	to operate it as a client. 
	- the latest ActivePerl has all the modules needed, except for https.

    Unix/Linux:

	make a subdirectory and cd to it
	tar -xzf Glynx-[version].tar.gz
	chmod +x glynx.pl                 (if necessary)
	pod2html glynx.pl -o=glynx.htm	  (this is optional)

	- under RedHat 6.2 I had to upgrade or install these modules:
	HTML::Tagset MIME:Base64 URI HTML::Parser Digest::MD5 libnet libwww-perl

	- to use https you will need:
	openssl (www.openssl.org) Net::SSLeay IO::Socket::SSL

    Please note that the software will create many files in 
    its work directory, so it is advisable to have a dedicated 
    sub-directory for it.

Goals:

	generalize 
		option to use (external) java and other script languages to extract links
		configurable file names and suffixes
		configurable dump file format
		plugins
		more protocols; download streams
		language support
	adhere to perl standards 
		pod documentation
		distribution
		difficult to understand, fun to write
	parallelize things and multiple computer support
	cpu and memory optimizations
	accept hardware/internet failures
		restartable
	reduce internet traffic
		minimize requests
		cache everything
	other (from perlhack.pod)
 		1. Keep it fast, simple, and useful.
		2. Keep features/concepts as orthogonal as possible.
		3. No arbitrary limits (platforms, data sizes, cultures).
		4. Keep it open and exciting to use/patch/advocate Perl everywhere.
		5. Either assimilate new technologies, or build bridges to them.

Problems (not bugs):

	- It takes some time to start the program; not practical for small single file downloads.
	- Command line only. It should have a graphical front-end; there exists a web front-end.
	- Hard to install if you don't have Perl or have outdated Perl modules. It works fine
	  with Perl 5.6 modules.
	- slave mode uses "dump files", and doesn't delete them.

To-do (long list):

	Bugs/debug/testing:
		- put // on exclude, etc if they don't have
		- arrays for $LOOP,$SUBST; accept multiple URL
		- Doesn't recreate unix links on "ftp". 
		Should do that instead of duplicating files (same on http redirects).
		- uses Accept:text/html to ask for an html listing of the directory when 
		in "ftp" mode. This will have to be changed to "text/ftp-dir-listing" if
		we implement unix links.
		- install and test "https"
		- accept --url=http://...
		- accept --batch=...grx
		- ignore/accept comments: <! a href="..."> - nested comments???
		- http server to make distributed downloads across the internet
		- use eval to avoid fatal errors; test for valid protocols
		- rename "old" .grx._BUSY_ files to .grx (timeout = 1 day?)
		  option: touch busy file to show activity
		- don't ignore "File:" 
		- unknown protocol is a fatal error
 		- test: counting MAX_DOCS with retry
 		- test: base-dir, out-depth, site leakage
		- test: authentication
		- test: redirect 3xx
			usar: www.ig.com.br ?
		- change the retry loop to a "while"
		- timeout changes after "slave"
		- leitura da configuracao:
		  (1) le opcoes da linha de comando (pode trocar o arquivo .ini), 
		  (2) le configuracao .ini, 
		  (3) le opcoes da linha de comando de novo (pode ser override .ini),
		  (4) le download-list-file
		  (5) le opcoes da linha de comando de novo (pode ser override download-list-file)
		- execute/override download-list-file "File:"
		  opcao: usar --subst=/k:\\temp/c:\\download/
	Generalization, user-interface:
		- opcao no-download para reprocessar o cache
		- arquivo de log opcional para guardar os headers. 
		  Opcao: filename._HEADER_; --log-headers
		- make it a Perl module (crawler, robot?), generic, re-usable 
		- option to understand robot-rules
		- make .glynx the default suffix for everything
		- try to support <form> through download-list-file
		- support mirroring (checking file dates)
		- internal small javascript interpreter
		- perl/tk front-end; finish web front end
		- config comment-string in download-list-file
		- config comment/uncomment for directives
 		- arquivo default para dump sem parametros - "dump-[n]-1"?
		- more configuration parameters
 		- opcao portugues/ingles?
		- plugins: for each chunk, page, link, new site, level change, dump file change, 
	  	  max files, on errors, retry level change. Opcao: usar callbacks.
		- dump suffix option
		- javascript interpreter option
		- scripting option (execute sequentially instead of parallel)
		- use environment
 		- aceitar configuracao --nofollow="shtml" e --follow="xxx"
 		- controle de hora, bytes por segundo
 		- protocolo pnm: - realvideo, arquivos .rpm
 		- streams
 		- gnutella
 		- 401 Authentication Required, generalize abort-on-error list, 
		  support --auth= (see rget)
 		- opcao para reescrever paginas html com links relativos
	Standards/perl:
		- packaging for distribution, include rfcs, etc?
		- include a default ini file in package
		- include web front-end in package?
		- installation hints, package version problems (abs_url)
		- more english writing
		- include all lwp-rget options, or ignore without exiting
 		- criar um objeto para as listas de links - escolher e especializar um existente.
 		- check: 19.4.5 HTTP Header Fields in Multipart Body-Parts
			Content-Encoding
			Persistent connections: Connection-header
			Accept: */*, *.*
 		- documentar melhor o uso de "\" em exclude e subst
 		- ler, enviar, configurar cookies
	Network/parallel support:		
		- timed downloads - start/stop hours
 		- gravar arquivo "to-do" durante o processamento, 
		para poder retomar em caso de interrupcao.
   		ex: a cada 10 minutos
 		- integrar com "k:\download"
		- receber / enviar comando restart / stop.
	Speed optimizations:
		- use an optional database connection
		- Persistent connections;
		- take a look at LWP::ParallelUserAgent
		- take a look at LWPng for simultaneous file transfers
		- take a look at LWP::Sitemapper
		- use eval around things do speed up program loading
 		- opcao: pilhas diferentes dependendo do tipo de arquivo ou site, para acelerar a procura
	Other:
 		- forms / PUT
 		- Renomear a extensao de acordo com o mime-type (ou copiar para o outro nome).
   		configuracao:	--on-redirect=rename 
                	  	--on-redirect=copy
				--on-mime=rename
				--on-mime=copy
 		- configurar tamanho maximo da URL
 		- configurar profundidade maxima de subdiretorios
 		- tamanho maximo do arquivo recebido
 		- disco cheio / alternate dir
 		- "--proxy=http:"1.1.1.1",ftp:"1.1.1.1"
  		  "--proxy="1.1.1.1"
  		    acessar proxy: $ua->proxy(...) Set/retrieve proxy URL for a scheme: 
  		    $ua->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');
  		    $ua->proxy('gopher', 'http://proxy.sn.no:8001/');
		- enable "--no-[option]"
		- accept empty "--dump" or "--no-dump" / "--nodump"
 		--max-mb=100
 			limita o tamanho total do download
 		--auth=USER:PASS
 			nao e' realmente necessario, pode estar dentro da URL
			existe no lwp-rget
 		--nospace
 			permite links com espacos no nome (ver lwp-rget)
 		--relative-links
 			opcao para refazer os links para relativo
 		--include=".exe" --nofollow=".shtml" --follow=".htm"
 			opcoes de inclusao de arquivos (procurar links dentro)
 		--full ou --depth=full
 			opcao site inteiro
 		--chunk=128000
		--dump-all
			grava todos os links, incluindo os ja existentes e paginas processadas


Version history:

 1.022:
	- multiple --prefix and --exclude seems to be working
	- uses Accept:text/html to ask for an html listing of the directory when in "ftp" mode.
	- corrected errors creating directory and copying file on linux


 1.021:
	- uses URI::Heuristic on command-line URL
	- shows error response headers (if verbose)
	- look at the 3rd parameter on 206 (when available -- otherwise it gives 500),
			Content-Length: 637055		--> if "206" this is "chunk" size
			Content-Range: bytes 1449076-2086130/2086131 --> THIS is file size
	- prefix of: http://rd.yahoo.com/footer/?http://travel.yahoo.com/
  	  should be: http://rd.yahoo.com/footer/
	- included: "wav"
	- sleep had 1 extra second
	- sleep makes tests even when sleep==0


 1.020: oct-02-2000
	- optimization: accepts 200, when expecting 206
	- don't keep retrying when there is nothing to do
	- 404 Not Found error sometimes means "can't connect" - uses "--404-retry"
	- file read = binmode


 1.019: - restart if program was modified (-M $0)
	- include "mov"
	- stop, restart


 1.018: - better copy, rename and unlink
	- corrected binary dump when slave
	- comparacao de tamanho de arquivos corrigida
 	- span e' um comando de css, que funciona como "a" (a href == span href);
	  span class is not java


 1.017: - sleep prints dots if verbose.
	- daemon mode (--slave)
	- url and input file are optional


 1.016: sept-27-2000
	- new name "glynx.pl"
	- verbose/quiet
	- exponential timeout on retry
	- storage control is a bit more efficient
	- you can filter the processing of a dump file using prefix, exclude, subst
	- more things in english, lots of new "to-do"; "goals" section
	- rename config file to glynx.ini


 1.015: - first published version, under name "get.pl"
	- rotina unica de push/shift sem repeticao
	- traduzido parcialmente para ingles, revisao das mensagens


 1.014: - verifica inside antes de incluir o link
 	- corrige numeracao dos arquivos dump
 	- header "Location", "Content-Base"
	- revisado "Content-Location"


 1.013: - para otimizar: retirar repeticoes dentro da pagina
	- incluido "png"
	- cria/testa arquivo "not-found"
	- processa Content-Location - TESTAR - achar um site que use
	- incluido tipo "swf", "dcr" (shockwave) e "css" (style sheet)
 	- corrige http://host/../file gravado em ./host/../file => ./file
 	- retira caracteres estranhos vindos do javascript: ' ;
	- os retrys pendentes sao gravados somente no final.
	- (1) le opcoes, (2) le configuracao, (3) le opcoes de novo


 1.012: - segmenta o arquivo dump durante o processamento, permitindo iniciar o
	download em paralelo a partir de outro processo/computador antes que a tarefa esteja
	totalmente terminada
	- utiliza indice para gravar o dump; nao destroi a lista que esta na memoria.
	- salva a configuracao completa junto com o dump; 
	- salva/le get.ini


 1.011: corrige autenticacao (prefix)
	corrige dump
	le dump
	salva/le $OUT_DEPTH, depth (individual), prefix no arquivo dump


 1.010: resume
	se o site nao tem resume, tenta de novo e escolhe o melhor resultado (ideia do Silvio)


 1.009: 404 not found nao enviado para o dump
       processa arquivo se o tipo mime for text/html (nao funciona para o cache)
       muda o referer dos links dependendo da base da resposta (redirect)
       considera arquivos de tamanho zero como "nao no cache"
       gera nome _INDEX_.HTM quando o final da URL tem "/". 


 1.008: trabalha internamente com URL absolutas
       corrige vazamento quando out-nivel=0


 1.007: segmenta o arquivo dump 
       acelera a procura em @processed
       corrige o nome do diretorio no arquivo dump


Other problems - design decisions to make

 - se usar '' no eval nao precisa de \\ ?
 - paginas html redirecionadas devem receber um tag <BASE> no texto?
 - montar links usando java ?
 - a biblioteca perl faz sozinha Redirection 3xx ?
 - usar File::Path para criar diretorios ?
 - applets sempre tem .class no fim?
 - file names excessivamente longos - o que fazer?
 - usar: $ua->max_size([$bytes]) - nao funciona com callback
 - mudar o filename se a base da resposta e diferente?
 - criar arquivo PART com tamanho zero quando da erro 408 - timeout
 - como e' o formato dump do go!zilla?

=head1 COPYRIGHT

Copyright (c) 2000 Flavio Glock <fglock@pucrs.br>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
This program was based on examples in the Perl distribution.


If you use it/like it, send a postcard to the author. 

=cut

@Config_Vars = qw/DEPTH TIMEOUT AGENT REFERER INDEXFILE SLEEP OUT_DEPTH BASE_DIR PART_SUFFIX MAX_DOCS INVALID_CHAR LOOP SUBST DUMP DUMP_MAX RETRY_MAX/;

@Config_Arrays = qw/PREFIX EXCLUDE/;

# Defaults
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
$RETRY_TIMEOUT_MULTIPLIER = 1.5;

# Defaults de uso interno, nao configuravel
$MAX_TESTE_REPETICAO =	30;	# testa os ultimos links antes de incluir na lista
$LIST_SIZE = 	3;		# tamanho da estrutura de @links = ($url, $referer, $nivel)

$DUMP_SUFFIX = 		".grx";
$TMP_SUFFIX =		"._TMP_";
$NOT_FOUND_SUFFIX = 	"._NOT_";
$BUSY_SUFFIX = 		"._BUSY_";
$DONE_SUFFIX = 		"._DONE_";
$GLYNX_SUFFIX =		".glynx";

$CFG_FILE =		"glynx.ini";

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

	# not implemented, but exist in lwp-rget:
	'hier'     	=> \&not_implemented('hier'),
	'auth=s'   	=> \&not_implemented('auth'),
	'iis'      	=> \&not_implemented('iis'),
	'tolower'  	=> \&not_implemented('tolower'),
	'nospace'  	=> \&not_implemented('nospace'),
	'keepext=s' 	=> \&not_implemented('keepext'),
    ) || usage();

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
		print "    [ $_: ", $$hashref{$_} , " ]\n" if $VERBOSE;
	}
	foreach(@Config_Arrays) {
		print "    [ $_: ", join(',', @{$$hashref{$_}} ) , " ]\n" if $VERBOSE;
	}
}


my $url;
$url = shift;	# optional url or input file

print "  [ $progname.pl Version $VERSION ]\n" if $VERBOSE;
print "  [ URL = $url ]\n" if $VERBOSE;

$url = uf_uristr($url);

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
	print "  [ LAST-PROGRAM-DATE: $0 = $Last_Program_Date ]\n" if $VERBOSE;

	$ua = LWP::UserAgent->new;
	$ua->agent($AGENT);
	$ua->timeout($TIMEOUT);

	$BASE_DIR = "." if ! $BASE_DIR;
	$BASE_DIR =~ s/\\/\//g;
	$BASE_DIR .= "/" if ! ($BASE_DIR =~ /\/$/);
	print "  [ BASE_DIR: $BASE_DIR ]\n" if $VERBOSE;

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
		$prefix->userinfo('');
		$prefix->params('');
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
		@dir = grep { /$DUMP_SUFFIX$/ && -f "$BASE_DIR$_" } @dir;
	closedir DIR;
	print "  [ SLAVE: $dir_expr: ", join(',',@dir), " ]\n" if $VERBOSE;
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
				else {
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
	my ($host, $port, $path, $params, $query);
	my ($name);

	$u1 = 		URI::URL->new($url);
	$host =		$u1->host;
	$port =		$u1->port;
	$path =		$u1->path;
	$params = 	$u1->params;
	$query =	$u1->query;

	$host .= '_' . $port if $port != 80;
	$path =~ tr/\\/\//;		   	# \

	# (opcao?) $path =~ s/\/$//g;	    	# / no final do path = "$"
	$path =~ s/\/$/\/$INDEXFILE/g;	    	# / no final do path = "/$INDEXFILE"

	$path =~ s/\/\w*?\/\.\.\//\//g;		# /../
	#     $query =~ tr/\\\/:\*\?\"<>\|/$/;
	eval '$query =~ tr/' . '\\' . '\\' . '\\/' . ':\*\?\"<>\|/' . $INVALID_CHAR . '/';
	$name = $host . $path;
	$name .= '$' . $query if $query;
	$name =~ s/\.$/\$/;		   	# ponto no final
	#     $name =~ tr/:\*\?\"<>\|/$/;
	eval '$name =~ tr/:\*\?\"<>\|/' . $INVALID_CHAR . '/';
	$name =~ s/\/\//\//g;		 	#  //

	# Win-NT charset:
	# 	allowed:	= & _ - space
	# 	not allowed:	\ / : * ? " < > |
	# Win-NT names with dots:
	#	allowed:	.* ..* ...*
	#			*.* *..* *...*
	#	not allowed:	. .. *.

 	# print "name: $name => $host $path $params $query\n";
	return $name;
}


sub make_dir {
	# o parametro para make_dir deve incluir a base
	my ($name) = @_;
	my (@a, $a, $b, $temp, $dest);
   	# cria o diretorio
	@a = split('/', $name);
	$a = '';
	foreach(0 .. $#a - 1) {
		$a .= $a[$_] . '/';
	}
	if (-d $a) {
		print "  [ DIR: $a ok ]\n" if $VERBOSE;
	} else {
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
}

sub my_unlink {
 	my ($source) = @_;
	if (-e $source) {
		unlink $source   or print "  [ ERR: UNLINK $source - $^E ]\n";  
	}
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
}

sub my_rename {
 	my ($source, $dest) = @_;
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

	if (-e $filename) {
		if (-d $filename) {
			print "  [ DIR EXISTS: $filename ]\n" if $VERBOSE;
			$filename .= '/' . $INDEXFILE;
			print "    [ CREATE FILE: $filename ]\n" if $VERBOSE;
			goto download_ok if (-s $filename);
		} elsif (-s $filename) {
			print "  [ FILE EXISTS: $filename ]\n" if $VERBOSE;
			goto download_ok;
		}
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

	if ($download_success and $res->is_success) {
		print "  [ OK: ", $res->status_line, " ]\n" if $VERBOSE;
		&my_rename ("$filename$PART_SUFFIX", "$filename");

		print "  [ GET: SUCCESS: UNLINK $filename$PART_SUFFIX-1 ]\n" if $VERBOSE;
		&my_unlink ("$filename$PART_SUFFIX-1");

		$num_docs++;

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

		print "  [ RESPONSE <<\n", $res->as_string, "    >> RESPONSE ]\n" if $VERBOSE;

		if ($res->content_type eq "text/ftp-dir-listing") {
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

		if ($res->content_type eq "text/html") {
			print "  [ HTML: Content-Type: text/html ]\n" if $VERBOSE;
			$mime_text_html = 1;
		} else {
			$mime_text_html = 0;
		}

		# REDIRECIONAMENTOS:
		# Location: indica que um novo documento deve ser obtido
		# Content-Location: indica o lugar onde este documento esta armazenado
		# Content-Base: indica o diretorio onde este documento esta armazenado

		$content_base = $res->header("Content-Base");
		if ($content_base) {
			$dir_base = &make_filename($content_base);
			&make_dir($dir_base);
		}

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
		    	$file_location = &make_filename($u1);
		    	$file_location = "$BASE_DIR$file_location";
		    	if ($filename ne $file_location) {
				# cria uma copia no lugar indicado
				$dest = $file_location;
				if (-d $file_location) {
					$dest = $file_location . '/' . $INDEXFILE;
					print "  [ Dir: $dest ]\n" if $VERBOSE;
				}
				if  (-e $dest) {
					print "  [ Arquivo ja existe: $file_location ]\n" if $VERBOSE;
				}  
				else {
					# verifica se existe o diretorio de destino
					&make_dir($dest);
					# copia
					$temp = $filename;
					$temp = $filename . '/' . $INDEXFILE if -d $filename;
					# print "  [ COPY $temp, $dest ]\n" if $VERBOSE;
					&my_copy($temp, $dest);
				}
			}
		} # fim: Content-Location

		# confere se esta no diretorio certo
		$base = $res->base;
		#$base_filename = &make_filename($base);
		#print " > BASE:      $base\n";
		#print " > BASE_FILE: $BASE_DIR$base_filename\n";
		#print " > URL:       $url\n";
		#print " > FILE:      $filename\n";
		# retirar o nome de arquivo da url e ver a diferenca com a nova base:
		$u1 = 		URI::URL->new($base);
		$base_path =	$u1->path;
		$base_path =~ 	s/[\w\.]*$//g;
		print "  [ BASE_PATH: $base_path ]\n" if $VERBOSE;
		$u1 = 		URI::URL->new($url);
		$path =		$u1->path;
		$path =~ 	s/[\w\.]*$//g;
		print "  [ URL_PATH:  $path ]\n" if $VERBOSE;
		#$url =~ /\/[\w]*/;
		if ($path ne $base_path) {
			print "  [ REDIRECT: Trocar referer do diretorio $path para $base_path ]\n" if $VERBOSE;
			$url =~ s/(.*)$path/$1$base_path/;
			print "  [ URL_NOVA:  $url]\n" if $VERBOSE;
			# o filename nao precisa ser mudado!
		}

download_ok:

	#$teste = eval "\$filename =~ $default_exclude";
	#print " ++ teste [$teste] $filename\n";

		if (    (($nivel - 1) >= 0) and
			( $mime_text_html or
			  ! (eval "\$filename =~ $default_exclude") )
			) {
			open (FILE, "$filename"); 
				binmode(FILE);
				@a = <FILE>; 
			close (FILE);
			chomp(@a); $_ = join(' ', @a);
			print "  [ CONTENTS <<\n$_\n    >> CONTENTS ]\n" if $VERBOSE;
			my @links1 = ();

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
			}

			# retira repeticoes
			@links1 = sort @links1;
			$prev = '';

			# monta a estrutura @links = ($url, $referer,  $nivel, ...)
			foreach (@links1) {
				# nao mailto:
				# nao file:
				# nao javascript: ou "javescript:"
				# nao vazio ou com espacos
				# nao repetido dentro da pagina
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
					&insert_url ($_, $url, $nivel  - 1);
				    }
				}
			}
		}       
	} else {
		print "  [ RESPONSE: ERROR <<\n", $res->as_string, "    >> RESPONSE ]\n" if $VERBOSE;
		$msg = $res->status_line;
		if (($msg =~ /404/) and (! $RETRY_404)) {
			print "    [ ERROR $msg => CANCEL ]\n" unless $QUIET;
			# cria arquivo not-found
			if (-e "$filename$PART_SUFFIX") {
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
		#	print "    [ ERROR $msg => DUMP ]\n";
		#	&insert_url_2 ($url, $referer, 0);	# marca como nivel zero
		} else {
			print "    [ ERROR $msg => LATER ]\n" unless $QUIET;
			push_list (\@retry, $url, $referer, $nivel);
			# print "    $retry -- push ", join(",", @retry) , " ($url, $referer, $nivel) \n";
		}
	}
	undef $req;
	undef $res;
} # fim: download

sub insert_url {
	my ($url, $referer, $nivel) = @_;
	my ($tmp, $tmp2);

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
			print "    [BIN => DUMP]\n" if $VERBOSE;
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
			print "    [ PUSH: repetido ]\n" if $VERBOSE;
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

Multi-process control:
  --slave           Wait until a download-list file is created (be a slave)
  --stop            Stop slave
  --restart         Stop and restart slave

Not implemented yet but won't generate fatal errors:
  --auth=USER:PASS  Set authentication credentials for web site
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

