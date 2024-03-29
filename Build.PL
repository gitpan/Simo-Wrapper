use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Simo::Wrapper',
    license             => 'perl',
    dist_author         => 'Yuki Kimoto <kimoto.yuki@gmail.com>',
    dist_version_from   => 'lib/Simo/Wrapper.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Simo' => 0.0805,
        'Simo::Constrain' => 0.0201,
        'Simo::Error' => 0.0206,
        'Encode' => 2.12,
        'XML::Simple' => '2.18'
    },
    add_to_cleanup      => [ 'Simo-Wrapper-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
