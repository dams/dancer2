package Dancer::Core::Role::Exception;
use Dancer::Moo::Types;

# This role makes the consumer a Dancer Exception class. Every Dancer
# exceptions class should consume this role.

use Moo::Role;

use strict;
use warnings;
use Carp;

# stringification
use overload '""' => sub {
    my ($self) = @_;
    $self->message
# TODO : not sure where Verbose should go
#      . ( $Dancer::Exception::Verbose ? $self->{_longmess} : $self->{_shortmess});
      . $self->{_shortmess};
};

# string comparison is done without the stack traces
use overload 'cmp' => sub {
    my ($e, $f) = @_;
    ( ref $e && $e->isa(__PACKAGE__)
      ? $e->message : $e )
      cmp
    ( ref $f && $f->isa(__PACKAGE__)
      ? $f->message : $f )
};

has _raised_arguments => (
    is => 'rw',
    isa => sub { ArrayRef(@_) },
    default => sub { [] },
);

has _shortmess => {
    is => 'rw',
    isa => sub { Str(@_) },
    default => sub { '' },
}

has _longmess => {
    is => 'rw',
    isa => sub { Str(@_) },
    default => sub { '' },
}

sub BUILD {}

after BUILD => sub {
    my ($self) = @_;
    $self->_raised_arguments([ @_ ]);
};

sub _message_pattern { '%s' }

sub throw {
    my $self = shift;
    $self->_raised_arguments(@_);
    local $Carp::CarpInternal;
    local $Carp::Internal;
    $Carp::Internal{'Dancer'} ++;
    $Carp::CarpInternal{'Dancer::Exception'} ++;
    $self->_shortmess(Carp::shortmess);
    $self->_longmess(Carp::longmess);
    die $self;
}

sub rethrow { die $_[0] }

sub message {
    my ($self) = @_;
    return sprintf($self->_message_pattern, @{$self->_raised_arguments});
}

1;
