# ftp.pm -- modified from Gisle Aas' "LWP::Protocol::ftp"
# by Flavio S. Glock
#
# oct-13-2000: Modified to include "REST" support

# $Id: ftp.pm,v 1.27 1999/11/04 20:25:51 gisle Exp $
# Implementation of the ftp protocol (RFC 959). We let the Net::FTP
# package do all the dirty work.

package ftp;

use Carp ();

use HTTP::Status ();
use HTTP::Negotiate ();
use HTTP::Response ();
use LWP::MediaTypes ();
use File::Listing ();
use Net::Cmd (CMD_MORE);

require LWP::Protocol;
@ISA = qw(LWP::Protocol);

use strict;
eval {
	require Net::FTP;
	Net::FTP->require_version(2.00);
};
my $init_failed = $@;

my $DEBUG = 0;


sub request
{
	# arg is the receive-data callback subroutine
	my($request, $timeout, $arg) = @_;

	print "  [ ftp::request BEGIN ]\n" if $DEBUG;
	if ($init_failed) {
		print "  [ ftp::request DONE 2 ]\n" if $DEBUG;
		return HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR, $init_failed);
	}

	my $size = 65536;
	my $method   = 'GET';

	my $url = $request->url;
	my $scheme   = $url->scheme;
	my $host	 = $url->host;
	my $port	 = $url->port;
	my $user	 = $url->user;
	my $password = $url->password;

	# If a basic autorization header is present than we prefer these over
	# the username/password specified in the URL.
	my($u,$p) = $request->authorization_basic;
	if (defined $u) {
		$user = $u;
		$password = $p;
	}

	# We allow the account to be specified in the "Account" header
	my $acct	 = $request->header('Account');

	# try to make a connection
	my $ftp = Net::FTP->new($host, Port => $port);
	unless ($ftp) {
		$@ =~ s/^Net::FTP: //;
		print "  [ ftp::request DONE 3 ]\n" if $DEBUG;
		return HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR, $@);
	}

	# Create an initial response object
	my $response = HTTP::Response->new(&HTTP::Status::RC_OK, "Document follows");
	$response->request($request);

	my $mess = $ftp->message;  # welcome message
	$mess =~ s|\n.*||s; # only first line left
	$mess =~ s|\s*ready\.?$||;
	# Make the version number more HTTP like
	$mess =~ s|\s*\(Version\s*|/| and $mess =~ s|\)$||;
	$response->header("Server", $mess);

	$ftp->timeout($timeout) if $timeout;

	print "  [ ftp::request Logging in as $user (password $password)... ]\n" if $DEBUG;
	unless ($ftp->login($user, $password, $acct)) {
		# Unauthorized.  Let's fake a RC_UNAUTHORIZED response
		my $res =  HTTP::Response->new(&HTTP::Status::RC_UNAUTHORIZED, scalar($ftp->message));
		$res->header("WWW-Authenticate", qq(Basic Realm="FTP login"));
		print "  [ ftp::request DONE 4 ]\n" if $DEBUG;
		return $res;
	}

	# Get & fix the path
	my @path =  grep { length } $url->path_segments;
	my $remote_file = pop(@path);
	$remote_file = '' unless defined $remote_file;

	$ftp->binary;

	for (@path) {
		unless ($ftp->cwd($_)) {
			print "  [ ftp::request DONE 5 ]\n" if $DEBUG;
			return HTTP::Response->new(&HTTP::Status::RC_NOT_FOUND, "Can't chdir to $_");
		}
	}

	unless ($method eq 'GET' || $method eq 'HEAD') {
		print "  [ ftp::request DONE 6 ]\n" if $DEBUG;
		return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				   "Illegal method $method");
	}

	if (my $mod_time = $ftp->mdtm($remote_file)) {
			$response->last_modified($mod_time);
			if (my $ims = $request->if_modified_since) {
				if ($mod_time <= $ims) {
					$response->code(&HTTP::Status::RC_NOT_MODIFIED);
					$response->message("Not modified");
					print "  [ ftp::request DONE 7 ]\n" if $DEBUG;
					return $response;
				}
			}
	}

	my $data;  # the ftp data handle
	my $content;

	# Range: bytes=9500-
	my $range = $request->header("Range");	# request
	my ($content_begin) = $range =~ /bytes\s?\=\s?(\d+)\s?\-/;

	print "  [ ftp::request remote_file: $remote_file ", length($remote_file), "]\n" if $DEBUG;
	print "  [ ftp::request header: ", $request->as_string, " ]\n" if $DEBUG;
	print "  [ ftp::request range: $range => $content_begin ]\n" if $DEBUG;

	# print "  [ ftp::response header: ", $response->as_string, " ]\n" if $DEBUG;
	# my $content_range = $request->header("Content-Range"); # response

	# my $ok = $ftp->quot("REST $content_begin");
	my $rest_ok = 0;
	unless ($ftp->_REST($content_begin)) {
		print "  [ ftp::request rest: error ]\n" if $DEBUG;
		$ftp->_REST(0);	# cancel last _REST
		$content_begin = 0;
	}
	else {
		$rest_ok = 1;
		print "  [ ftp::request rest: ok ]\n" if $DEBUG;
	}

	if (length($remote_file) and $data = $ftp->retr($remote_file)) {
		print "  [ ftp::request remote_file: $remote_file ]\n" if $DEBUG;
		my($type, @enc) = LWP::MediaTypes::guess_media_type($remote_file);
		$response->header('Content-Type',   $type) if $type;
		for (@enc) {
			$response->push_header('Content-Encoding', $_);
		}
		my $mess = $ftp->message;
		my $content_length = 0;
		print "  [ ftp::request mess: $mess $type ]\n" if $DEBUG;
		if ($mess =~ /\((\d+)\s+bytes\)/) {
			$content_length = $1;
			$response->header('Content-Length', $content_length);
		}

		if ($method ne 'HEAD') {

			# Read data from server into callback
			do {
				my ($size_read, $data_end);
				eval { $size_read = $data->read($content, $size); };
				print "  [ ftp::request Data: $size_read ]\n" if $DEBUG;
				# print "  [ ftp::request Content: ",length($content)," ]\n" if $DEBUG;
				# print "  [ ftp::request Size: $size ]\n" if $DEBUG;

				if (! $size_read) {
					# possibly a timeout
					$@ = 'No data';
					print "  [ ftp::request No data ]\n" if $DEBUG;
					$response->code(&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
					$response->header('X-Died' => $@);
					$response->message("FTP close response: " . $ftp->code . " " . $ftp->message);
					$data->close;
					return $response;
				}

				if ($rest_ok and ! $@) {
					$data_end = $content_begin + $size_read;
					$response->header("Content-Range", "bytes ${content_begin}-${data_end}/$content_length");
					$response->code(&HTTP::Status::RC_PARTIAL_CONTENT);
					print "  [ ftp::request Content-Range: ", $response->header("Content-Range"), " ]\n" if $DEBUG;
					$content_begin = $data_end;
				}

				eval { &$arg($content, $response, undef ); } unless $@;
				if ($@) {
					chomp($@);
					$response->header('X-Died' => $@);
					last;
				}
			} while $content;
		}	# if ne HEAD

		unless ($data->close) {
			# Something did not work too well
			if ($method ne 'HEAD') {
						$response->code(&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
						$response->message("FTP close response: " . $ftp->code .
						   " " . $ftp->message);
			}
		}
	} elsif (!length($remote_file) || $ftp->code == 550) {
			print "  [ ftp::request remote_file: (none) ]\n" if $DEBUG;
			# 550 not a plain file, try to list instead
			if (length($remote_file) && !$ftp->cwd($remote_file)) {
					print "  [ chdir before listing failed ]\n" if $DEBUG;
					print "  [ ftp::request DONE 8 ]\n" if $DEBUG;
					return HTTP::Response->new(&HTTP::Status::RC_NOT_FOUND,
					   "File '$remote_file' not found");
			}

			# It should now be safe to try to list the directory
			my @lsl = $ftp->dir;

			# Try to figure out if the user want us to convert the
			# directory listing to HTML.
			my @variants = (
		 		  ['html',  0.60, 'text/html'			],
		 		  ['dir',   1.00, 'text/ftp-dir-listing' ]
			);
			#$HTTP::Negotiate::DEBUG=1;
			my $prefer = HTTP::Negotiate::choose(\@variants, $request);

			my $content = '';

			if (!defined($prefer)) {
				print "  [ ftp::request DONE 9 ]\n" if $DEBUG;
				return HTTP::Response->new(&HTTP::Status::RC_NOT_ACCEPTABLE,
				   "Neither HTML nor directory listing wanted");
			} elsif ($prefer eq 'html') {
				$response->header('Content-Type' => 'text/html');
				$response->header('Content-Location' => "$url/") unless $url =~ /\/$/;
				$content = "<HEAD><TITLE>File Listing</TITLE>\n";
				$content .= "</HEAD>\n<BODY>\n";
				$content .= "<H1>Directory listing of $url</H1>\n";
				$content .= "<PRE><A HREF=\"..\">Up to higher level directory</A>\n";
				# my $base = $request->url->clone;
				# my $path = $base->epath;
				# $base->epath("$path/") unless $path =~ m|/$|;
				# $content .= qq(<BASE HREF="$base">\n</HEAD>\n);

				for (File::Listing::parse_dir(\@lsl, 'GMT')) {
						my($name, $type, $size, $mtime, $mode) = @$_;
						$content .= qq(  <LI> <a href="$name">$name</a>);

						# $type, $size, $mtime, $mode);

						$content .= " $size bytes" if $type eq 'f';
						$content .= " =&gt; $1" if $type =~ /l\s*(.*)/;

						$content .= "";	# \n or PRE
				}
				$content .= "</PRE></BODY>\n";
			} else {
				$response->header('Content-Type', 'text/ftp-dir-listing');
				$content = join("\n", @lsl, '');
			}

			$response->header('Content-Length', length($content));

			if ($method ne 'HEAD') {
				# $response = LWP::Protocol::collect_once($arg, $response, $content);
				eval { &$arg($content, $response, undef ); };	# send content
				eval { &$arg(undef, $response, undef ); };	# finish
			}
	} else {
		print "  [ ftp::request Returning message instead of file. data=[$data] ]\n" if $DEBUG;
		my $res = HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST, "FTP return code " . $ftp->code);
		$res->content_type("text/plain");
		$res->content($ftp->message);
		print "  [ ftp::request DONE 10 ]\n" if $DEBUG;
		return $res;
	}

	print "  [ ftp::request DONE 1 ]\n" if $DEBUG;
	return $response;
}

# "pod" removed. See LWP::Protocol::ftp

1;
