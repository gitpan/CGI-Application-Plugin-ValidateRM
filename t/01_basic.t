use Test::More tests => 10;
BEGIN { use_ok('CGI::Application::Plugin::ValidateRM') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestApp1;
my $t1_obj = TestApp1->new(QUERY=>CGI->new("email=broken;rm=form_process"));
my $t1_output = $t1_obj->run();

like($t1_output, qr/Some fields below/, 'err__');

like($t1_output, qr/name="email".*Invalid/, 'basic invalid');

like($t1_output,qr/name="phone".*Missing/, 'basic missing');

my $t2_obj = TestApp1->new(QUERY=>CGI->new("email=broken;rm=form_process_with_ref"));
my $t2_output = $t2_obj->run();

like($t2_output, qr/Some fields below/, 'err__');

like($t2_output, qr/name="email".*Invalid/, 'basic invalid');

like($t2_output,qr/name="phone".*Missing/, 'basic missing');

my $t3_obj = TestApp1->new(QUERY=>CGI->new("email=broken;passwd=anything;rm=form_process_with_fif_opts"));
my $t3_output = $t3_obj->run();

unlike($t3_output, qr/anything/, 'passing options to HTML::FillInForm works');

{
    use UNIVERSAL (qw/can/);
    ok( $t3_obj->can('dfv'), "has dfv method" );
    ok( defined $t3_obj->dfv->invalid('email'), "content of DFV method is as expected" );

}
