use strict;
use warnings;
use Test::Exception;
use Test::More tests => 11;

use ok 'MooseX::PartialObject';

{ package Class;
  use Moose;
  has 'foo' => ( init_arg => 'the_value_for_foo', reader => 'FOO', isa => 'Int', required => 1 );
  has 'bar' => ( is => 'ro', isa => 'Str', required => 1 );
}

my $p = MooseX::PartialObject->new( class => Class->meta );
isa_ok $p, 'MooseX::PartialObject';

lives_ok {
    $p->set( foo => 42 );
} 'setting foo is ok';

throws_ok {
    $p->set( NOT_A_SLOT => 'oh hai' );
} qr/'NOT_A_SLOT' is not a valid attribute in 'Class'/;

throws_ok {
    $p->set( foo => 'A string' );
} qr/type constraint/, 'type constraint is checked';

throws_ok {
    $p->expand
} qr/is required/, 'required attributes are required';

lives_ok {
    $p->set( bar => 'Hello' );
};

my $c;
lives_ok {
    $c = $p->expand;
} 'expand lives now';

isa_ok $c, 'Class';
is $c->FOO, 42, 'foo slot read via FOO accessor';
is $c->bar, 'Hello', 'bar slot read via bar accessor';
