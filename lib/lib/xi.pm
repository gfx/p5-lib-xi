package lib::xi;
use 5.008_001;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.05';

use File::Which ();
use Config      ();

sub cpanm_path {
    my($self) = @_;
    $self->{cpanm_path} ||= File::Which::which('cpanm')
                            || $self->fatal('cpanm is not available');
}

sub new {
    my($class, %args) = @_;
    return bless \%args, $class;
}

# must be fully-qualified; othewise implied ::INC.
sub lib::xi::INC {
    my($self, $file) = @_;

    my @args = (@{ $self->{cpanm_opts} }, $file);
    if(system($^X, $self->cpanm_path, @args) == 0) {
        foreach my $lib (@{ $self->{myinc} }) {
            if(open my $inh, '<', "$lib/$file") {
                $INC{$file} = "$lib/$file";
                return $inh;
            }
        }
    }

    return;
}

sub import {
    my($class, @cpanm_opts) = @_;

    my $install_dir;

    if(@cpanm_opts && $cpanm_opts[0] !~ /^-/) {
        require File::Spec;
        $install_dir = File::Spec->rel2abs(shift @cpanm_opts);
    }

    my @myinc;

    if($install_dir) {
        @myinc = (
            "$install_dir/lib/perl5",
            "$install_dir/lib/perl5/$Config::Config{archname}",
        );
        push @INC, @myinc;

        unshift @cpanm_opts, '-l', $install_dir;
    }

    push @INC, $class->new(
        install_dir => $install_dir,
        myinc       => $install_dir ? \@myinc : \@INC,
        cpanm_opts  => \@cpanm_opts,
    );
    return;
}

sub fatal {
    my($self, @messages) = @_;
    require Carp;
    my $class = ref($self) || $self;
    Carp::croak("[$class] ", @messages);
}

1;
__END__

=head1 NAME

lib::xi - Installs missing modules on demand

=head1 VERSION

This document describes lib::xi version 0.05.

=head1 SYNOPSIS

    # to install missing libaries automatically
    $ perl -Mlib::xi script.pl

    # with cpanm options
    $ perl -Mlib::xi=-q script.pl

    # to install missing libaries to extlib/ (with cpanm -l extlib)
    $ perl -Mlib::xi=extlib script.pl

    # with cpanm options
    $ perl -Mlib::xi=extlib,-q script.pl

=head1 DESCRIPTION

When you execute a script found in, for example, C<gist>, you'll be annoyed
at missing libraries and will install those libraries by hand with a CPAN
client. We have repeated such a task, which violates the great virtue of
Laziness. Stop doing it! Make computers do it!

C<lib::xi> is a pragma to install missing libraries if and only if they are
required.

The mechanism is that when the perl interpreter cannot find a library required,
this pragma try to install it with C<cpanm(1)> and tell it to the interpreter.

=head1 INTERFACE

=head2 The import method

=head3 C<< use lib::xi ?$install_dir, ?@cpanm_opts >>

Setups the C<lib::xi> hook into C<@INC>.

If I<$install_dir> is specified, it is used as the install directory as
C<cpanm --local-lib $install_dir>, adding C<$install_dir/lib/perl5> to C<@INC>
(i.e. C<use lib::xi 'extlib'> also means C<use lib 'extlib/lib/perl5'>).

If the first argument starts with C<->, it is regarded as C<@cpanm_opts>.

I<@cpanm_opts> are passed to C<cpanm(1)>.

See L<perlfunc/require> for the C<@INC> hook specification details.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<cpanm> (App::cpanminus)

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
