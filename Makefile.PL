use inc::Module::Install;

name 'MooseX-PartialObject';
all_from 'lib/MooseX/PartialObject.pm';

build_requires 'Test::More';
build_requires 'ok';

WriteAll();
