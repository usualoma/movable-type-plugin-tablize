# Copyright (c) 2010 ToI Inc. All rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# $Id$

package Tablize;

use warnings;
use strict;

sub _hdlr_tablize {
	my ($ctx, $args, $cond) = @_;
	my $per_row = $args->{'tablize_per_row'}
		or die 'per_row is required';
	my $tag = $args->{'tablize_tag'}
		or die 'tag is required';

	local $ctx->{__stash}{'tablize_per_row'} = $per_row;
	local $ctx->{__stash}{'tablize_index'}   = -1;

	#my $vars = $ctx->{__stash}{vars} ||= {};
	#local $vars->{__first__} = !$i;

	my $tokens  = $ctx->stash('tokens');

	my @sentinels = grep({
		lc($_->[0]) eq lc('TablizeSentinel')
	} @$tokens);

	my @is_last_in_rows = grep({
		lc($_->[0]) eq lc('TablizeIsLastInRow')
	} @$tokens);

 	my $container_args = { %$args };
	delete $container_args->{'@'};

	my $container = bless [
		'TablizeContainer',
		$container_args,
		$tokens,
		[],
		undef,
		undef,
		$tokens->[0][5],
		$tokens->[0][6],
	], 'MT::Template::Node';


	my $tablize_target = bless [
		$tag,
		$container_args,
		bless([ $container ], 'MT::Template::Tokens'),
		[],
		undef,
		undef,
		$tokens->[0][5],
		$tokens->[0][6],
	], 'MT::Template::Node';

	$ctx->stash('tokens', bless([ $tablize_target ], 'MT::Template::Tokens'));

	my $result = $ctx->slurp($args, $cond);


	my $index = $ctx->stash('tablize_index');
	if (@sentinels) {
		my $builder = $ctx->stash('builder');
		while ($index % $per_row != $per_row - 1) {
			$index++;

			for my $t (@sentinels) {
				my $tmp = $builder->build($ctx, bless([ $t ], 'MT::Template::Tokens'), $cond);
				return $ctx->error($builder->errstr) unless defined $tmp;
				$result .= $tmp;
			}

			if ($index % $per_row == $per_row - 1) {
				for my $t (@is_last_in_rows) {
					my $tmp = $builder->build($ctx, bless([ $t ], 'MT::Template::Tokens'), $cond);
					return $ctx->error($builder->errstr) unless defined $tmp;
					$result .= $tmp;
				}
			}
		}
	}

	$result;
}

sub _hdlr_tablize_container {
	my ($ctx, $args, $cond) = @_;

	my $stash   = $ctx->{__stash};
	my $index   = ++$stash->{'tablize_index'};
	my $per_row = $stash->{'tablize_per_row'};

	$ctx->slurp($args, {
		%$cond,
		TablizeIsFirstInRow =>
			$index % $per_row == 0,
		TablizeIsLastInRow  =>
			$index % $per_row == $per_row - 1,
		TablizeSentinel => 0,
	});
}

1;
