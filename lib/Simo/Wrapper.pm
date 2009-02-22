package Simo::Wrapper;
use Simo;
use Carp;

our $VERSION = '0.0203';

use Simo::Constrain qw( is_class_name is_object );

# accessor ( by Simo )
sub obj{ ac }

# constructor
sub create{
    my $self = shift->SUPER::new( @_ );
}


# object builder
sub new{
    my $self = shift;
    
    my $obj = $self->obj;
    croak "'new' must be called form class or object." 
        if !is_object( $obj ) && !is_class_name( $obj );
    
    $self->obj( $self->obj->new( @_ ) );
    return $self;
}


# get value specify attr names
sub get_attrs{
    my ( $self, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'get_attrs' must be called from object." unless is_object( $obj );
    
    @attrs = @{ $attrs[0] } if ref $attrs[0] eq 'ARRAY';
    
    my @vals;
    foreach my $attr ( @attrs ){
        croak "Invalid key '$attr' is passed to get_attrs" unless $obj->can( $attr );
        my $val = $obj->$attr;
        push @vals, $val;
    }
    wantarray ? @vals : $vals[0];
}

# get value as hash specify attr names
sub get_attrs_as_hash{
    my ( $self, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'get_attrs_as_hash' must be called from object." unless is_object( $obj );
    
    my @vals = $obj->get_attrs( @attrs );
    
    my %attrs;
    @attrs{ @attrs } = @vals;
    
    wantarray ? %attrs : \%attrs;
}

# set values
sub set_attrs{
    my ( $self, @args ) = @_;
    
    my $obj = $self->obj;
    croak "'set_attrs' must be called from object." unless is_object( $obj );
    
    # check args
    @args = %{ $args[0] } if ref $args[0] eq 'HASH';
    croak 'key-value pairs must be passed to set_attrs' if @args % 2;
    
    # set args
    while( my ( $attr, $val ) = splice( @args, 0, 2 ) ){
        croak "Invalid key '$attr' is passed to set_attrs" unless $obj->can( $attr );
        no strict 'refs';
        $obj->$attr( $val );
    }
    return $self;
}

# run methods
sub run_methods{
    my ( $self, @method_or_args_list ) = @_;
    
    my $obj = $self->obj;
    croak "'run_methods' must be called from object." unless is_object( $obj );
    
    my $method_infos = $self->_SIMO_parse_run_methods_args( $obj, @method_or_args_list );
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

sub _SIMO_parse_run_methods_args{
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

sub cycle_attrs{
    my ( $self, $code, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'cycle_attrs' must be called from object." unless is_object( $obj );
    
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

sub encode_attrs{
    my ( $self, $encoding, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'encode_attrs' must be called from object." unless is_object( $obj );
    
    require Encode;
    $self->cycle_attrs(
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

sub decode_attrs{
    my ( $self, $encoding, @attrs ) = @_;
    
    my $obj = $self->obj;
    croak "'decode_attrs' must be called from object." unless is_object( $obj );
    
    require Encode;
    $self->cycle_attrs(
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

=head1 NAME

Simo::Wrapper - Object wrapper to manipulate attrs and methods.

=cut

=head1 VERSION

Version 0.0203

=cut

=head1 DESCRIPTION

This class is designed to be used by L<Simo::Util> o function.

So this class is not used by itself.

Please read L<Simo::Util> documentation.

=head1 CAUTION

Simo::Wrapper is yet experimental stage.

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

1; # End of Simo::Wrapper
