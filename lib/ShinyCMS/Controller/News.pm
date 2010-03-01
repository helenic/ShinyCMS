package ShinyCMS::Controller::News;

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::News

=head1 DESCRIPTION

Controller for ShinyCMS news section.

=head1 METHODS

=cut


=head2 base

=cut

sub base : Chained('/') : PathPart('news') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
}


=head2 view_items

=cut

sub view_items : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my @news = $c->model('DB::NewsItem')->search(
		{ },
		{ order_by => 'posted desc',
		  limit => 10 },
	);
	$c->stash->{ news_items } = \@news;
}


=head2 view_item

=cut

sub view_item : Chained('base') : PathPart('') : Args(3) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ news_item } = $c->model('DB::NewsItem')->search(
		url_title => $url_title,
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	)->first;
}


=head2 list_items

=cut

sub list_items : Chained('base') : PathPart('list-items') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @news = $c->model('DB::NewsItem')->search(
		{ },
		{ order_by => 'posted desc' }
	);
	$c->stash->{ news_items } = \@news;
}


=head2 add_item

=cut

sub add_item : Chained('base') : PathPart('add') : Args(0) {
	my ( $self, $c, $item_id ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to add news items.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a news admin
	unless ( $c->user->has_role('News Admin') ) {
		$c->stash->{ error_msg } = 'You do not have the ability to add news items.';
		$c->response->redirect( '/news' );
	}
	
	$c->stash->{ template } = 'news/edit_item.tt';
}


=head2 add_do

=cut

sub add_do : Chained('base') : PathPart('add-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check user privs
	die unless $c->user->has_role('News Admin');	# TODO
	
	# Add the item
	my $item = $c->model('DB::NewsItem')->create({
		author    => $c->user->id,
		title     => $c->request->param('title'    ),
		url_title => $c->request->param('url_title'),
		body      => $c->request->param('body'     ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'News item added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item->id ) );
}


=head2 edit_item

=cut

sub edit_item : Chained('base') : PathPart('edit') : Args(1) {
	my ( $self, $c, $item_id ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit news items.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a news admin
	unless ( $c->user->has_role('News Admin') ) {
		$c->stash->{ error_msg } = 'You do not have the ability to edit news items.';
		$c->response->redirect( '/news' );
	}
	
	# Stash the news item
	$c->stash->{ news_item } = $c->model('DB::NewsItem')->find({
		id => $item_id,
	});
}


=head2 edit_do

=cut

sub edit_do : Chained('base') : PathPart('edit-do') : Args(1) {
	my ( $self, $c, $item_id ) = @_;
	
	# Check user privs
	die unless $c->user->has_role('News Admin');	# TODO
	
	# Perform the update
	my $item = $c->model('DB::NewsItem')->find({
		id => $item_id,
	})->update({
		title     => $c->request->param('title'    ),
		url_title => $c->request->param('url_title'),
		body      => $c->request->param('body'     ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'News item updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item_id ) );
}




=head1 AUTHOR

Denny de la Haye <2010@denny.me>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

1;

