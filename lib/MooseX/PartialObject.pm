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

sub _check_slot {
    my ($self, $slot_name) = @_;
    confess "'$slot_name' is not a valid attribute in '@{[$self->class->name]}'"
      unless $self->class->get_meta_instance->is_valid_slot($slot_name);
}

sub get {
    my ($self, $slot_name) = @_;
    $self->_check_slot($slot_name);
    $self->_get_class_attribute($slot_name)->get_value($self->partial_instance);
}

sub set {
    my ($self, $slot_name, $value) = @_;
    $self->_check_slot($slot_name);
    $self->_get_class_attribute($slot_name)->set_value($self->partial_instance, $value);
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
