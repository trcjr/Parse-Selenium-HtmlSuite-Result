package Tests::Parse::Selenium::HtmlSuite::Result::Base;
use Test::Class::Most attributes => qw/ sample_test_result_files /;
use Smart::Comments;
use FindBin;
use File::Find qw(find);
use Try::Tiny;

sub startup : Tests(startup) {
    my $self = shift;
    $self->sample_test_result_files(
        sub {
            my @sample_test_result_files;
            my $data_dir = "$FindBin::Bin/test_case_data";
            find sub {
                push @sample_test_result_files, $File::Find::name
                  if -f $File::Find::name;
            }, $data_dir;
            $self->{_sample_test_result_files} = \@sample_test_result_files;
          }
          ->()
    );
}

sub setup : Tests(setup) {
}

sub teardown : Tests(teardown) {
}

sub shutdown : Tests(shutdown) {
}

1;
