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

# THESE ARE SUBROUTINES - THIS FILE IS NOT INTENDED TO BE EXECUTED

sub glynx_configure {
	$base_dir = "k:/download/download/";
	$log_dir =  "k:/download/download/";
}

sub glynx_menu {
	my %in = @_;
	print <<EOT;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML><HEAD><TITLE>Glynx - Download Manager</TITLE>
</HEAD><BODY><H1>Glynx - Download Manager</H1>
EOT

	$_ = $in{url};
	tr/\\/\//;
	($in{url}, $resto) = /^(.*?)(\/?)$/;
	$_ = $in{url};
	if ((! /http:/) and (! /ftp:/)) {
		$_ = "http://" . $_;
		s/\/\/\//\/\//;
	}
	$in{url} = $_;

  	print <<ENDOFTEXT;
$addr
 <P><FORM method="post">
 URL: <input name="url" value="$in{url}" size="80"><br>

 Depth: <input name=depth value=$in{depth}><br>

 Prefix: <input name="base" value="$in{base}" size="60"><br>

 Label: <input name=label value=$in{label}><br>

 Other options: <input name=options value=$in{options}><br>

 <input type="submit">
 </FORM>

<pre>Obs: 
  URL = http://site/directory/file

  Depth 0 = 1 file  
  Depth 1 = 1 file + links & images
  Depth 2 = links their images

  Prefix = site/directory, limits unnecessary downloads (optional)

  Label = job name

  Options = (not ready yet)
</pre>
ENDOFTEXT


	if (($in{url} ne "") and ($in{url} ne "http\:\/\/")) { 

		print "<hr>";

		$in{depth} = $in{depth} + 0;
		$in{depth} = 5 if ($in{depth} > 5);

		$in{label} =~ s/[\s\+]//;
		$in{label} = "default" unless $in{label};

		$in{base} = $in{url} unless $in{base};

		open (FILE, ">>${log_dir}glynx.log");
		print FILE <<EOT;
ip:    $addr
URL:   $in{url}
Depth: $in{depth}
Base:  $in{base}
Label: $in{label}

EOT
		close (FILE);

		$cmd = "$base_dir$in{label}.grx";
		open (FILE, ">$cmd");
		print FILE <<EOT;
//DUMP: '$in{label}'
//PREFIX: '$in{base}'
//
URL: $in{url}
//Referer: .
//Depth: $in{depth}
EOT
close (FILE);

  	}
	print end_html;
}

1;


