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

use HTTP::Daemon;
use strict;

package myCGI;

use CGI qw/:standard unescape/;
use vars '@ISA';
@ISA=qw(HTTP::Daemon::ClientConn);
require "./glynx_menu.pl";

sub cgi
{
    	my ($self, $a, $query, $r);
	my %in = ();
    	$self = shift;
    	$r = shift;
	my ($method, $url, $header, $content, $headers) = 
	   ($r->method, $r->url, $r->header, $r->content, $r->headers_as_string);
	select $self;
	&glynx_configure;
	foreach (split("\&", $header)) {
		$in{$1} = unescape($2) if /(.*)=(.*)/;
	}
	&glynx_menu(%in);
	select STDOUT;
}

package main;

  my ($d, $c, $r);
  my $Default_Server_Port = 8081;
  my $Server_Port = shift || $Default_Server_Port;
  $d = new HTTP::Daemon LocalPort => $Server_Port;
  $c = new myCGI;
  print "Glynx - Download Manager\n";
  print "User interface server running at ", $d->url, "\n";
  while ($c = $d->accept) {   # $c = HTTP::Daemon::ClientConn
      $r = $c->get_request;   # $r = HTTP::Request
      if ($r) {
	  if (($r->method eq 'GET') or ($r->method eq 'POST')) {
              $c->send_basic_header();
              $c->send_response();
              bless $c, "myCGI";
              $c->cgi($r);
	  } else {
	      $c->send_error("RC_FORBIDDEN")
	  }
      }
      $c = undef;  # close connection
  }

1;
