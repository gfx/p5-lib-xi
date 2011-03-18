#!perl -w
use strict;
use Test::More;
use lib::xi ();
use File::Path qw(rmtree);

# preload libs dynamically loaded
use Cwd      ();
use overload ();
use Scalar::Util ();

BEGIN { rmtree 'xt-extlib'; @INC = () }
END   { rmtree 'xt-extlib';  }
use lib::xi 'xt-extlib', '-q';

use install; # a dummy module

ok -d 'xt-extlib', '-d xt-extlib';
like $INC{'install.pm'}, qr/\Qinstall.pm\E \z/xms, 'collectly installed';

done_testing;
