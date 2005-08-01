use Test::More tests => 4;
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{ package MyForward::Test; use base 'CGI::Application'; use
    CGI::Application::Plugin::ValidateRM;

    sub setup { my $self = shift; $self->start_mode('legacy_process');
        $self->run_modes([qw/legacy_process legacy_form/]); }

    sub legacy_form { my $self = shift;
        Test::More::is($self->get_current_runmode, 'legacy_process', "if
            ::Forward is not loaded, current_rm is not updated");
        $self->header_type('none'); return "legacy form output HUH"; }

    sub legacy_process { my $self = shift; my ($results, $err_page) =
        $self->check_rm('legacy_form', { required => 'fail' }); return
        $err_page if $err_page; return 'legacy process completed'; }

    my $app = MyForward::Test->new(); my $out = $app->run();
    Test::More::is($out, 'legacy form output', "form is returned");
}

SKIP: {
    package MyForward::TestForward;
    use base 'CGI::Application';
    use CGI::Application::Plugin::ValidateRM;
    eval { require CGI::Application::Plugin::Forward; };
    if ($@) {
        Test::More::skip "CGI::Application::Plugin::Forward required", 2;
    }

    sub setup {
        my $self = shift;
        $self->start_mode('forward_process');
        $self->run_modes([qw/forward_process forward_form/]);
    }

    sub forward_form {
        my $self = shift;
        Test::More::is($self->get_current_runmode, 'forward_form', 
            "if ::Forward is loaded, current_rm is updated");
        $self->header_type('none');
        return "forward form output HUH";
    }

    sub forward_process {
        my $self = shift;
        my ($results, $err_page) = $self->check_rm('forward_form', { required => 'fail' });
        return $err_page if $err_page;
    }

    my $app = MyForward::TestForward->new();
    my $out = $app->run();
    Test::More::is($out, 'forward form output', "form is returned");
}
