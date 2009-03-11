package Simo::Wrapper;
use Simo;

our $VERSION = '0.0216';

use Carp;
use Simo::Error;
use Simo::Constrain qw( is_class_name is_object );

# accessor ( by Simo )
sub obj{ ac }

# constructor
sub create{
    my $self = shift->SUPER::new( @_ );
}

sub new{
    my $self = shift;
    
    my $obj = $self->obj;
    
    if( is_class_name( $obj ) ){
        eval "require $obj";
    }
    else{
        unless( is_object( $obj ) ){
            croak "'new' must be called from class or object.";
        }
    }
    
    croak "'$obj' must be have 'new'." unless $obj->can( 'new' );
    return $self->obj->new( @_ );
}

sub connect{
    my $self = shift;
    
    my $obj = $self->obj;
    
    if( is_class_name( $obj ) ){
        eval "require $obj";
    }
    else{
        unless( is_object( $obj ) ){
            croak "'connect' must be called from class or object.";
        }
    }
    
    croak "'$obj' must be have 'connect'." unless $obj->can( 'connect' );
    return $self->obj->connect( @_ );
}

# object builder( return self )
sub build{
    my $self = shift;
    
    my $obj = $self->obj;
    
    if( is_class_name( $obj ) ){
        eval "require $obj";
    }
    else{
        unless( is_object( $obj ) ){
            croak "'build' must be called from class or object.";
        }
    }
    
    croak "'$obj' must be have 'new'." unless $obj->can( 'new' );
    $self->obj( $self->obj->new( @_ ) );
    return $self;
}

sub validate{
    my ( $self, @args ) = @_;
    my $obj = $self->obj;
    my $pkg = ref $obj;
    croak "Cannot call 'validate' from class" unless $pkg;
    
    # check args
    @args = %{ $args[0] } if ref $args[0] eq 'HASH';
    croak "key-value pairs must be passed to 'validate'" if @args % 2;
    
    # set args
    while( my ( $attr, $validator ) = splice( @args, 0, 2 ) ){
        croak "Attr '$attr' is not exist" unless $obj->can( $attr );
        croak "Value must be code reference" unless ref $validator eq 'CODE';
        
        local $_ = $obj->$attr;
        my $info = {};
        my $ret = $validator->( $_, $info );
        if( !$ret ){
            Simo::Error->throw( 
                type => 'value_invalid',
                msg => "${pkg}::$attr must be valid value",
                pkg => $pkg,
                attr => $attr,
                val => $_,
                info => $info
            );
        }
    }
    return $self;
}

# new object and validate
sub new_and_validate{
    my ( $self, @args ) = @_;
    
    if( ref $args[0] eq 'HASH' && ref $args[0] eq 'HASH' ){
        my $always_valid = sub{ 1 };
        foreach my $attr ( keys %{ $args[0] } ){
            $args[1]->{ $attr } = $always_valid unless exists $args[1]->{ $attr }
        }
        return $self->build( $args[0] )->validate( $args[1] )->obj;
    }
    else{
        croak "key-value-validator pairs must be passed to 'new_and_validate'."
            if @args % 3;
        
        my @key_value_pairs;
        my @key_validator_pairs;
        while( my ( $key, $val, $validator ) = splice( @args, 0, 3 ) ){
            push @key_value_pairs, $key, $val;
            push @key_validator_pairs, $key, $validator;
        }
        return $self->build( @key_value_pairs )->validate( @key_validator_pairs )->obj;
    }
}

sub new_from_objective_hash{
    my ( $self, @args ) = @_;
    
    my $obj = $self->obj;
    
    # check args
    @args = %{ $args[0] } if ref $args[0] eq 'HASH';
    croak "key-value pairs must be passed to 'new_from_objective_hash'." if @args % 2;
    my %args = @args;
    
    my $class = ref $obj || $obj;
    $class ||= $args{ __CLASS };
    delete $args{ __CLASS };
    
    my $constructor = delete $args{ __CLASS_CONSTRUCTOR } || 'new';
    
    while( my ( $attr, $val ) = each %args ){
        if( ref $args{ $attr } eq 'HASH' && $args{ $attr }->{ __CLASS } ){
            $val = Simo::Wrapper->create->new_from_objective_hash( $args{ $attr } );
        }
        $args{ $attr } = $val;
    }

    eval "require $class";
    {
        croak "'$class' do not have '$constructor' method." unless $class->can( $constructor );
        no strict 'refs';
        $obj = $class->$constructor( %args );
    }
    return $obj;
}

sub new_from_xml{
    my ( $self, $xml ) = @_;
    require XML::Simple;
    
    my $objective_hash = XML::Simple->new->XMLin( $xml );
    
    $self->obj( undef );
    return $self->new_from_objective_hash( $objective_hash );
}

# get value specify attr names
sub get_values{
    my ( $self, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'get_values' must be called from object." unless is_object( $obj );
    
    @attrs = @{ $attrs[0] } if ref $attrs[0] eq 'ARRAY';
    
    my @vals;
    foreach my $attr ( @attrs ){
        croak "Invalid key '$attr' is passed to get_values" unless $obj->can( $attr );
        my $val = $obj->$attr;
        push @vals, $val;
    }
    wantarray ? @vals : $vals[0];
}

# get value as hash specify attr names
sub get_hash{
    my ( $self, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'get_hash' must be called from object." unless is_object( $obj );
    
    my @vals = $self->get_values( @attrs );
    
    my %values;
    @values{ @attrs } = @vals;
    
    wantarray ? %values : \%values;
}

# set values
sub set_values{
    my ( $self, @args ) = @_;
    
    my $obj = $self->obj;
    croak "'set_values' must be called from object." unless is_object( $obj );
    
    # check args
    @args = %{ $args[0] } if ref $args[0] eq 'HASH';
    croak "key-value pairs must be passed to 'set_values'." if @args % 2;
    
    # set args
    while( my ( $attr, $val ) = splice( @args, 0, 2 ) ){
        croak "Invalid key '$attr' is passed to 'set_values'" unless $obj->can( $attr );
        no strict 'refs';
        $obj->$attr( $val );
    }
    return $self;
}


# set values
sub set_values_from_objective_hash{
    my ( $self, @args ) = @_;
    
    my $obj = $self->obj;
    croak "'set_values_from_objective_hash' must be called from object." unless is_object( $obj );
    
    # check args
    @args = %{ $args[0] } if ref $args[0] eq 'HASH';
    croak "key-value pairs must be passed to 'set_values_from_objective_hash'" if @args % 2;
    
    # set args
    my %args = @args;
    while( my ( $attr, $val ) = each %args ){
        if( $attr eq '__CLASS' || $attr eq '__CLASS_CONSTRUCTOR' ){
            delete $args{ $attr };
            next;
        }
        
        croak "Invalid key '$attr' is passed to 'set_values_from_objective_hash'" unless $obj->can( $attr );
        if( ref $args{ $attr } eq 'HASH' && $args{ $attr }->{ __CLASS } ){
            $val = Simo::Wrapper->create->new_from_objective_hash( $args{ $attr } );
        }
        no strict 'refs';
        $obj->$attr( $val );
    }
    return $self;
}

sub set_values_from_xml{
    my ( $self, $xml ) = @_;
    require XML::Simple;
    
    my $objective_hash = XML::Simple->new->XMLin( $xml );
    
    $self->set_values_from_objective_hash( $objective_hash );
    return $self;
}

# run methods
sub run_methods{
    my ( $self, @method_or_args_list ) = @_;
    
    my $obj = $self->obj;
    croak "'run_methods' must be called from object." unless is_object( $obj );
    
    my $method_infos = $self->_parse_run_methods_args( $obj, @method_or_args_list );
    while( my $method_info = shift @{ $method_infos } ){
        my ( $method, $args ) = @{ $method_info }{ qw( name args ) };
        
        if( @{ $method_infos } ){
            $obj->$method( @{ $args } );
        }
        else{
            return wantarray ? ( $obj->$method( @{ $args } ) ) :
                                 $obj->$method( @{ $args } );
        }
    }
}

*call = \&run_methods;

sub _parse_run_methods_args{
    my ( $self, $obj, @method_or_args_list ) = @_;
    
    my $method_infos = [];
    while( my $method_or_args = shift @method_or_args_list ){
        croak "$method_or_args is bad. Method name must be string and args must be array ref"
            if ref $method_or_args;
        
        my $method = $method_or_args;
        croak "$method is not exist" unless $obj->can( $method );
        
        my $method_info = {};
        $method_info->{ name } = $method;
        $method_info->{ args } = ref $method_or_args_list[0] eq 'ARRAY' ?
                                 shift @method_or_args_list :
                                 [];
        
        push @{ $method_infos }, $method_info;
    }
    return $method_infos;
}

sub filter_values{
    my ( $self, $code, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'filter_values' must be called from object." unless is_object( $obj );
    
    croak "First argument must be code reference." unless ref $code eq 'CODE';
    
    foreach my $attr ( @attrs ){
        croak "'$attr' is not exist." unless $obj->can( $attr );
        
        $obj->$attr unless exists $obj->{ $attr }; # initialized if attr is not called yet.
        
        if( ref $obj->{ $attr } eq 'ARRAY' ){
            foreach my $i ( 0 .. @{ $obj->{ $attr } } - 1 ){
                my $info = { type => 'ARRAY', attr => $attr, index => $i, self => $obj };
                
                $obj->{ $attr }[ $i ] = $code->( $obj->{ $attr }[ $i ], $info );
            }
        }
        elsif( ref $obj->{ $attr } eq 'HASH' ){
            foreach my $key ( keys %{ $obj->{ $attr } } ){
                my $info = { type => 'HASH', attr => $attr, key => $key, self => $obj };
                
                $obj->{ $attr }{ $key } = $code->( $obj->{ $attr }{ $key }, $info );
            }
        }
        else{
            my $info = { type => 'SCALAR', attr => $attr, self => $obj };
            $obj->{ $attr } = $code->( $obj->{ $attr }, $info );
        }
    }
}

sub encode_values{
    my ( $self, $encoding, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'encode_values' must be called from object." unless is_object( $obj );
    
    require Encode;
    $self->filter_values(
        sub{
            my ( $val, $info ) = @_;
            
            my ( $type, $attr ) = @{ $info }{ qw( type attr ) };
            
            if( ref $val ){
                my $warn = $type eq 'ARRAY'  ? "\$self->{ '$attr' }[ $info->{ index } ] must be string. Encode is not done." :
                           $type eq 'HASH'   ? "\$self->{ '$attr' }{ '$info->{ key }' } must be string. Encode is not done." :
                           $type eq 'SCALAR' ? "\$self->{ '$attr' } must be string or array ref or hash ref. Encode is not done." :
                           '';
                carp $warn;
                return $val;
            }
            return Encode::encode( $encoding, $val );
        },
        @attrs
    );
}

sub decode_values{
    my ( $self, $encoding, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'decode_values' must be called from object." unless is_object( $obj );
    
    require Encode;
    $self->filter_values(
        sub{
            my ( $val, $info ) = @_;
            
            my ( $type, $attr ) = @{ $info }{ qw( type attr ) };
            
            if( ref $val ){
                my $warn = $type eq 'ARRAY'  ? "\$self->{ '$attr' }[ $info->{ index } ] must be string. Decode is not done." :
                           $type eq 'HASH'   ? "\$self->{ '$attr' }{ '$info->{ key }' } must be string. Decode is not done." :
                           $type eq 'SCALAR' ? "\$self->{ '$attr' } must be string or array ref or hash ref. Decode is not done." :
                           '';
                carp $warn;
                return $val;
            }
            return Encode::decode( $encoding, $val );
        },
        @attrs
    );
}

sub clone{
    my ( $self ) = @_;
    
    my $obj = $self->obj;
    croak "'clone' must be called from object." unless is_object( $obj );
    
    require Storable;
    return Storable::dclone( $obj );
}

sub freeze{
    my ( $self ) = @_;
    
    my $obj = $self->obj;
    croak "'freeze' must be called from object." unless is_object( $obj );
    
    require Storable;
    return Storable::freeze( $obj );
}

sub thaw{
    my ( $self, $freezed ) = @_;
    
    require Storable;
    return Storable::thaw( $freezed );
}

# The following method is renamed. Don't use these method .
*get_attrs = \&get_values;
*get_attrs_as_hash = \&get_hash;
*set_attrs = \&set_values;
*encode_attrs = \&encode_values;
*decode_attrs = \&decode_values;
*filter_attrs = \&filter_values;
*set_attrs_from_objective_hash = \&set_values_from_objective_hash;
*set_attrs_from_xml = \&set_values_from_xml;

1;
__END__

=head1 NAME

Simo::Wrapper - Wrapper class to manipulate object.

=cut

=head1 VERSION

Version 0.0216

=head1 CAUTION

Simo::Wrapper is yet experimental stage.

Please wait until Simo::Wrapper will be stable.

=cut

=head1 SYNOPSIS

    use Simo::Util 'o';
    # new
    my $book = o('Book')->new( title => 'Good day', price => 1000 );

    # connect
    my $dbh = o('DBI')->connect( 'dbi:SQLite:db_name=test_db', '', '' );
    
    # new_and_validate
    my $book = o('Book')->new_and_validate(
        title => 'a', sub{ length $_ < 30 },
        price => 1000, sub{ $_ > 0 && $_ < 50000 },
    );
    
    my $book = o('Book')->new_and_validate(
        { title => 'a', price => 'b' },
        { title=> sub{ length $_ < 30 }, price => sub{ $_ > 0 && $_ < 50000 } }
    );
    
    # set_values
    o($book)->set_values( title => 'Good news', author => 'kimoto' );
    
    # get_values
    my ( $title, $author ) = o($book)->get_values( qw/ title author / );
    
    # get_hashs
    my $hash = o($book)->get_hash( qw/ title author / );
    
    # run_method
    o($book_list)->run_methods(
        find => [ 'author' => 'kimoto' ],
        sort => [ 'price', 'desc' ],
        'get_result'
    );
    
    # filter_values
    my $result = o($book)->filter_values(
        sub{ uc $_ },
        qw/ title author /,
    );
    
    # encode_values and decode_values
    o($book)->encode_values( 'utf8', qw/ title author / );
    o($book)->decode_values( 'utf8', qw/ title author / );
    
    # clone
    my $book_copy = o($book)->clone;
    
    # freeze and thaw
    my $book_freezed = o($book)->freeze;
    my $book = o->thaw( $book_freezed );
    
    # new_from_xml and set_values_from_xml
    my $book = o->new_from_xml( $xml_file );
    o($book)->set_values_from_xml( $xml_file );
    
=head1 DESCRIPTION

Simo::Wrapper is the collection of methods to manipulate a object.

=over 4

=item use a class not calling 'require' or 'use'

-> new

'new' automatically load the class, and call 'new' method.

=item create a object and validate values

-> new_and_validate

=item set or get multiple values

-> set_values, get_value, get_hash

=item call multiple methods

-> run_methods

=item convert multiple values

-> filter_values

=item encode or decode multiple values

-> encode_values, decode_values

=item clone,freeze or thaw the object

-> clone, freeze, thaw

= item create a object form xml

-> new_from_xml

=item set values from xml

-> set_values_from_xml

=back

Simo::Wrapper is designed to be used from L<Simo::Util> o function.
See also L<Simo::Util>

=head1 FUNCTION

Simo::Wrapper object is usually used from L<Simo::Util> o function,
so the following sample is explained using this function.

please write this at frist.

    use Simo::Util qw( o );

=head2 new

'new' is a object constructor. 
Unlike normal 'new', this 'new' load class automatically and construct object.

    my $book = o('Book')->new( title => 'Good day', price => 1000 );

You no longer call 'require' or 'use'.

=head2 connect

'connect' is the same as 'new'.

I prepare 'connect' method because classes like 'DBI' has 'connect' method as the object constructor.

    my $dbh = o('DBI')->connect( 'dbi:SQLite:db_name=test_db', '', '' );


=head2 build

'build' is the same as 'new' except return Simo::Wrapper object.

=head2 validate

'validate' is the method for validating.

    my $book = Book->new( title => 'Good time', price => 3000);
    $book->validate(
        title => sub{ length $_ < 30 },
        prcie => sub{ $_ > 0 && $_ < 3000 }
    );

If validator function return false value, 'validate' throw L<Simo::Error> object.

'value_invalid' is set to 'type' field of L<Simo::Error> object.

=head2 new_and_validate

'new_and_validate' construct object and validate object.

You can use 2 type of argument.

First: key-value-validator

    my $book = o('Book')->new_and_validate(
        title => 'a', sub{ length $_ < 30 },
        price => 1000, sub{ $_ > 0 && $_ < 50000 },
        auhtor => 'Kimoto', sub{ 1 }
    );
    
If you do not validate some field, you pass sub{ 1 } to validator.

Second: { key => valu }, { key => validator }

    my $book = o('Book')->new_and_validate(
        { title => 'a', price => 'b' },
        { title=> sub{ length $_ < 30 }, price => sub{ $_ > 0 && $_ < 50000 } }
    );

This method return constructed object.

=head2 get_values

'get_values' get the values.

    my ( $title, $author ) = o($book)->get_values( qw/ title author / );

=head2 get_hash

'get_hash' get the hash of specified fields.
    
    my $book = Book->new( title => 'Good cat', author => 'Kimoto', price => 3000 );
    my $hash = o($book)->get_hash( qw/ title author / );

$hash is that

    {
        title => 'Good cat',
        auhtor => 'Kimoto'
    }

=head2 set_values

'set_values' set values of the object.

    o($book)->set_values( title => 'Good news', author => 'kimoto' );

You can also pass hash reference

    o($book)->set_values( { title => 'Good news', author => 'kimoto' } );

=head2 new_from_objective_hash

'new_from_objective_hash' construct object from a I<objective hash>.

    my $book = o->new_from_objective_hash( $objective_hash );

You maybe hear the name of I<objective hash> at first.

I<objective hash> is the hash that contain the information of object accroding to the following rules.

=over 4

=item 1. '__CLASS' is class name.

=item 2. '__CLASS_CONSTRUCTOR' is object constructor name. If this is ommited, 'new' is used as constructor name.

=back

objective hash sample is

    my $objective_hash = { 
        __CLASS => 'Book',
        __CLASS_CONSTRUCTOR => 'new',
        
        title => 'Good thing',
        
        author => {
            __CLASS => 'Person',
            
            name => 'Kimoto',
            age => 19,
            country => 'Japan'
        },
        
        price => 2600
    };

'Person' object is automatically constructed and set to 'author' field.

After that, 'Book' object is constructed .

=head2 new_from_xml

'new_from_xml' construct object from a XML file.

    my $book = o->new_from_xml( $xml_file );

XML file sample is

    <?xml version="1.0" encoding='UTF-8' ?>
    <root __CLASS="Book" >
      <title>Good man</title>
      
      <author __CLASS="Person">
        <name>Kimoto</name>
        <age>28</age>
        <country>Japan</country>
      </author>
    </root>

You can use the xml using the form of objective hash.
See also 'new_from_objective_hash'.

The xml parser of this method is 'XML::Simple'.
See also L<XML::Simple>

=head2 set_values_from_objective_hash

'set_values_from_objective_hash' set values from a I<objective hash>.

    o($book)->set_values_from_objective_hash( $objective_hash );

See also 'new_from_objective_hash'.

=head2 set_values_from_xml

'set_values_from_xml' set values loading from XML file.

    o($book)->set_values_from_xml( $xml_file );
    
You can use the xml using the form of objective hash.
See also 'new_from_objective_hash'.

The xml parser of this method is 'XML::Simple'.
See also L<XML::Simple>

=head2 run_methods

'run_methods' call multiple methods.

    my $result = o($book_list)->run_methods(
        find => [ 'author' => 'kimoto' ],
        sort => [ 'price', 'desc' ],
        'get_result'
    );

This method return the return value of last method
( this example, retrun value of 'get_result' )

=head2 call

'call' is aliase of 'run_methods'

=head2 filter_values

'filter_values' convert multiple values.
    
    o($book)->filter_values( sub{ uc $_ }, qw/ title author / );

$book->title and $book->author is converted to upper case.
    
This method also filter the values of array ref.

    $book->author( [ 'Kimoto', 'Matuda' ] );
    o($book)->filter_values( sub{ uc $_ }, qw/ author / );

'Kimoto' and 'Matuda' is converted to upper case.

This method also filter the values of hash ref.

    $book->info( { country => 'Japan', quality => 'Good' } );
    o($book)->filter_values( sub{ uc $_ }, qw/ info / );

'Japan' and 'Good' is converted to upper case.

These 'filter_values' logic is used by 'encode_values' and 'decode_values'.

=head2 encode_values

'encode_values' encode multiple values.

    o($book)->encode_values( 'utf8', qw/ title author / );

$book->title and $book->author is encoded.

This method also encode the values of array ref.

    $book->author( [ 'Kimoto', 'Matuda' ] );
    o($book)->encode_values( 'utf8', qw/ author / );

'Kimoto' and 'Matuda' is encoded.

This method also encode the values of hash ref.

    $book->info( { country => 'Japan', quality => 'Good' } );
    o($book)->encode_values( 'utf8', qw/ info / );

'Japan' and 'Good' is encoded.

=head2 decode_values

'decode_values' decode multipul values.

    o($book)->decode_values( 'utf8', qw/ title author / );

$book->title and $book->author is decoded.

This method also decode the values of array ref.

    $book->author( [ 'Kimoto', 'Matuda' ] );
    o($book)->decode_values( 'utf8', qw/ author / );

'Kimoto' and 'Matuda' is decoded.

This method also decode the values of hash ref.

    $book->info( { country => 'Japan', quality => 'Good' } );
    o($book)->decode_values( 'utf8', qw/ info / );

'Japan' and 'Good' is decoded.

=head2 clone

'clone' copy the object deeply.

    my $book_copy = o($book)->clone;

'clone' is the same as Storable::clone.
See also L<Storable>

=head2 freeze

'freeze' serialize the object.

    my $book_freezed = o($book)->freeze;

'freeze' is the same as Storable::freeze.
See also L<Storable>

=head2 thaw

'thaw' resotre the freezed object.

    my $book = o->thaw( $book_freezed );

'thaw' is the same as Storable::thaw.
See also L<Storable>

=head2 create

'create' is constructor of 'Simo::Wrapper'.

=head2 obj

'obj' is wrapped object.
    
    my $book = o($book)->obj;

o($book)->obj is equel to $book.

=cut

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-simo-wrapper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Simo-Wrapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Simo::Wrapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Simo-Wrapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Simo-Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Simo-Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/Simo-Wrapper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

