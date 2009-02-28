package MooseX::PartialObject;
use Moose;

has 'class' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Class',
    required => 1,
    handles  => {
        _get_attribute => 'get_attribute',
    },
);

has 'partial_instance' => (
    is      => 'ro',
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
        $self->_get_attribute($slot_name)->$method($self->partial_instance, @args)
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

__END__

=head1 NAME

MooseX::PartialObject - build an object incrementally

=head1 SYNOPSIS

    { package Class; use Moose; has [qw/foo bar/] => ( is => 'ro', required => 1 ) }

    my $partial = MooseX::PartialObject->new(
        class => Class->meta,
    );

    $partial->set('foo', 42);
    $partial->set('bar', 13);
    $partial->set('made_up_name', 1); # throws an exception

    my $real = $self->expand;
    say $real->foo + $real->bar
