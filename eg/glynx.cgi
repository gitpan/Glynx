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

use CGI qw/:standard/;
require "./glynx_menu.pl";
&glynx_configure;
$query = new CGI;
%in = $query->Vars;
&glynx_menu(%in);

1;


