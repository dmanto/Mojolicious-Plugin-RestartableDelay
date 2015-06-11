package Mojolicious::Plugin::RestartableDelay;
use Mojo::Base 'Mojolicious::Plugin';


sub register {
	my ($self, $app) = @_;
	$app->helper( restartable_delay => \&_restartable_delay );
}

sub _restartable_delay {
	my $c=shift;
	my $cb = pop;
	my @steps = @_;
	Mojo::IOLoop::Delay->new->steps(
		@steps,
		sub {
			my ($d, $more) = @_;
			if ($more) {_restartable_delay($c,@steps,$cb)} else {$cb->(@_)}
			}
		);
	}

1;
