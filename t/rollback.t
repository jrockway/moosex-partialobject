use strict;
use warnings;
use Test::More tests => 2;

use MooseX::PartialObject;

{ package Class;
  use Moose;
  has 'an_attribute' => ( is => 'ro', required => 1 );
}


my $rb = 0;
{
    my $p = MooseX::PartialObject->new( class => Class->meta );
    $p->set( an_attribute => 'some file' );
    $p->add_rollback_hook( sub { $rb = 1 } );
    is $rb, 0;
}

is $rb, 1, 'rollback worked';
