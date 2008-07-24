package MooseX::PartialObject;
use Moose;
use MooseX::AttributeHelpers;

has 'class' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Class',
    required => 1,
    handles  => {
        _get_class_attribute => 'get_attribute',
    },
);

has 'rollback_hooks' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[CodeRef]',
    default   => sub { +[] },
    provides  => {
        push => 'add_rollback_hook',
    },
);

has 'partial_instance' => (
    is      => 'ro',
    isa     => 'Class',
    lazy    => 1,
    default => sub { shift->class->get_meta_instance->create_instance },
);

# add get/set
for my $dir (qw/get set/){
    __PACKAGE__->meta->add_method( $dir => sub {
        my ($self, $slot_name, @args) = @_;
        my $method = "${dir}_value";
        confess "'$slot_name' is not a valid attribute in '@{[$self->class->name]}'"
          unless $self->class->get_meta_instance->is_valid_slot($slot_name);
        $self->_get_class_attribute($slot_name)->$method($self->partial_instance, @args);
    });
}
    
sub expand {
    my $self = shift;
    my %init_args =
      map  { @$_ }
      grep { defined $_->[1] }
      map  { [ $_->init_arg, $self->get($_->name) ] }
        $self->class->compute_all_applicable_attributes;
    
    return $self->class->name->new( \%init_args );
}

1;

=pod TODO

perhaps we should make this a role that causes required attributes to
be ignored until a read is attempted.  i'm not sure how to implement
that, though.  the role would need to make all attributes lazy and for
the default C<default> be C<die>.

Example:

  package Foo;
  use Moose;
  with 'MooseX::Traits';
  has [qw/tons of attributes and then some more/] => (
     is       => 'ro',
     required => 1,
     whatever => 'you_want',
  );

  sub a {
     return $self->tons + $self->of;
  }

  sub b {
     return $self->attributes

  package main;
  use Foo;

  my $foo = Foo->new_with_traits( traits => ['PartialObject'] );
  ## Foo=HASH(0x123456)
  $foo->set_attribute( tons => 42 );
  $foo->set_attribute( of   => -2 );
  $foo->a; 
  ## 40
  $foo->b;
  ## Error: "attempt to access uninitialized slot" or something

This is probably bad because BUILD (etc.) will never be run.  It might
be useful though.

=cut
