package CGI::Application::Plugin::ValidateRM;
use HTML::FillInForm;
use Data::FormValidator;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	check_rm
	validate_rm	
);

$VERSION = '1.22';

sub check_rm {
     my $self = shift;
	 my $return_rm = shift || die 'missing required return run mode';
     my $profile_in = shift || die 'missing required profile';
     my $fif_params = shift || {}; 

	# If the profile is not a hash reference, 
	# assume it's a CGI::App method
	my $profile;
	if (ref $profile_in eq 'HASH') {
		$profile = $profile_in;
	}
	else {
        if ($self->can($profile_in)) {
            $profile = $self->$profile_in();
        }
        else {
            $profile = eval { $self->$profile_in() };
            die "Error running profile method '$profile_in': $@" if $@;
        }

	}
 
     require Data::FormValidator;
     my $dfv = Data::FormValidator->new({}, $self->param('dfv_defaults') );

	my $r =$dfv->check($self->query,$profile);

	my $err_page;
	if ($r->has_missing or $r->has_invalid) {
		 my $return_page = $self->$return_rm($r->msgs);
         my $return_pageref = (ref($return_page) eq 'SCALAR')
             ? $return_page : \$return_page;
		 require HTML::FillInForm;
		 my $fif = new HTML::FillInForm;
		 $err_page = $fif->fill(
             scalarref => $return_pageref,
			 fobject => $self->query,
             %$fif_params,
		 );
	}
	return ($r,$err_page);
}

sub validate_rm {
	my $self = shift;
	my ($r,$err_page) = $self->check_rm(@_);
	return (scalar $r->valid,$err_page);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

CGI::Application::Plugin::ValidateRM - Help validate CGI::Application run modes using Data::FormValidator

=head1 SYNOPSIS

 use CGI::Application::Plugin::ValidateRM (qw/check_rm/);

 my ($results,$err_page) = $self->check_rm('form_display','_form_profile');
  return $err_page if $err_page; 


 # Optionally, you can pass additional options to HTML::FillInForm->fill()
 my ($results,$err_page) = $self->check_rm('form_display','_form_profile', { fill_password => 0 });
  return $err_page if $err_page; 

=head1 DESCRIPTION

CGI::Application::Plugin::ValidateRM helps to validate web forms when using the
CGI::Application framework and the Data::FormValidator module. 

=head2 check_rm

This CGI::Application method takes three inputs and returns two outputs. Its
return values are a L<Data::FormValidator::Results> object and, if any fields
defined in the profile are missing or invalid, an error page.
The inputs are as follows:

=over

=item Return run mode

This run mode will be used to generate an error page, with the form re-filled
(using HTML::FillInForm) and error messages in the form. This page will be
returned as a second output parameter.

The errors will be passed in as a hash reference, which can then be handed to a
templating system for display.  

The fields should be prepared using Data::FormValidator's
built-in support for returning error messages as a hash reference.   
See the documentation for C<msgs> in the L<Data::FormValidator::Results>
documentation.

Returning the errors with a prefix, such as "err_" is recommended. Using
C<any_errors> is also recommended to make it easy to display a general "we have
some errors" message.  

HTML::Template users may want to pass C<die_on_bad_params=E<gt>0> to the
HTML::Template constructor to prevent the presence of the "err_" tokens from
triggering an error when the errors are I<not> being displayed.

=item Data::FormValidator profile

This can either be provided as a hash reference, or as the name
of a CGI::Application method that will return such a hash reference.

=item HTML::FillInForm options (optional)

If desired, you can pass additional options to the HTML::FillInForm C<fill>
method through a hash reference. See an example above. 

=back

Additionally, the value of the 'dfv_defaults' param from the calling
object is optionally used to pass defaults to the C<new()> constructor.

  $self->param('dfv_defaults')

By setting this to a hash reference of defaults in your C<cgiapp_init> routine
in your own super-class, you could make it easy to share some default settings for
Data::FormValidator across several forms. Of course, you could also set parameter
through an instance script via the PARAMS key.

Here's an example that I've used:

 sub cgiapp_init {
     my $self = shift;
 
     # Set some defaults for DFV unless they already exist.  
     $self->param('dfv_defaults') ||
         $self->param('dfv_defaults', {
                 missing_optional_valid => 1,
                 filters => 'trim',
                 msgs => {
                     any_errors => 'err__',
                     prefix     => 'err_',
                     invalid    => 'Invalid',
                     missing    => 'Missing',
                     format => '<span class="dfv-errors">%s</span>',
                 },
             });
 }

Now all my applications that inherit from a super class with this
C<cgiapp_init()> routine and have these defaults, so I don't have
to add them to every profile. 

=head2 validate_rm 

Works like C<check_rm> above, but returns the old style C<$valid> hash
reference instead of the results object.

=head1 EXAMPLE

In a CGI::Application module:

 # This is the run mode that will be validated. Notice that it accepts
 # some errors to be passed in, and on to the template system.
 sub form_display {
 	my $self = shift;
 	my $errs = shift;
 
 	my $t = $self->load_tmpl('page.html');
 
 	$t->param($errs) if $errs;
 	return $t->output;
 }
 
 sub form_process {
 	my $self = shift;
 
 	use CGI::Application::Plugin::ValidateRM (qw/check_rm/);
 	my ($results, $err_page) = $self->check_rm('form_display','_form_profile');
 	return $err_page if $err_page; 

	#..  do something with DFV $results object now
 
 	my $t = $self->load_tmpl('success.html');
 	return $t->output;

 }
 
 sub _form_profile {
 	return {
 		required => 'email',
		msgs => {
			any_errors => 'some_errors', 
			prefix => 'err_',
		},
 	};
 }

In page.html:

 <!-- tmpl_if some_errors -->
 	<h3>Some fields below are missing or invalid</h3>
 <!-- /tmpl_if -->
 <form>
 	<input type="text" name="email"> <!-- tmpl_var err_email -->
 </form>


=head1 SEE ALSO

L<CGI::Application>, L<Data::FormValidator>, L<HTML::FillInForm>, perl(1)

=head1 AUTHOR

Mark Stosberg <mark@summersault.com>

=head1 MAILING LIST

If you have any questions, comments, bug reports or feature suggestions,
post them to the support mailing list! This the Data::FormValidator list. 
To join the mailing list, visit L<http://lists.sourceforge.net/lists/listinfo/cascade-dataform>

=head1 LICENSE

Copyright (C) 2003 Mark Stosberg <mark@summersault.com>

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,

or

b) the "Artistic License" 

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

For a copy of the GNU General Public License along with this program; if not,
write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA


=cut

