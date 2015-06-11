BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Test::Mojo;

require_ok ("pg_nb2.pl");

my $t = Test::Mojo->new;

$t->get_ok('/blocking/50')->status_is(200);
my @body_b = split /\n/, $t->tx->res->body;
like $body_b[50], qr /I ♥ Mojolicious!: # 1/, "blocking: all records";

$t->get_ok('/non-blocking/50')->status_is(200);
my @body_nb = split /\n/, $t->tx->res->body;
like $body_nb[50], qr /I ♥ Mojolicious!: # 1/, "non-blocking: all records";

done_testing();
