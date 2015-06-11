#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Pg;
use Time::HiRes qw (time);
use lib 'lib';

my $defnr =  5_000;
my $maxnr = 30_000;

app->secrets(['something']);

helper pg => sub { state $pg = Mojo::Pg->new('postgresql:///test?pg_enable_utf8=1') };

plugin 'RestartableDelay';

app->pg->migrations->from_data->migrate;

get '/' => sub {
  my $c = shift;
  $c->render(text => sprintf('Rendered from pid %05u, timestamp: %08.5f', $$, time))
};

get '/blocking/:nr' => {nr => $defnr} => [nr => qr/[1-9]\d*/] => sub {
  my $c = shift;
  $c->inactivity_timeout(300);
  $c->res->headers->content_type('text/plain;charset=UTF-8');
  $c->write( 'Results:');
  my ($rmn, $tstart) = ($c->stash('nr'), time);
  while ($rmn) {
    my $results = $c->pg->db->query('select * from app_test where id=?', 1 + ($rmn-1) % $maxnr);
    my $sal = sprintf("\n%08.5f: PID: %05u, Pg PID: %05u, Index %05u -> %s",
        time - $tstart, $$, $c->pg->db->pid, $rmn--, $results->hash->{stuff});
    utf8::encode($sal);
    $c->write($sal);
  }
  $c->finish("\n");
};

get '/non-blocking/:nr' => {nr => $defnr} => [nr => qr/[1-9]\d*/] => sub {
  my $c = shift;
  $c->res->headers->content_type('text/plain;charset=UTF-8');
  $c->write( 'Results:');
  my ($rmn, $tstart) = ($c->stash('nr'), time);
  $c->restartable_delay(
    sub {
          $c->pg->db->query(
            'select * from app_test where id=?', 1 + ($rmn-1) % $maxnr => shift->begin);
          },
    sub {
          my ($d, $err, $results) = @_;
          my $sal = sprintf("\n%08.5f: PID: %05u, Pg PID: %05u, Index %05u -> %s",
              time - $tstart, $$, $c->pg->db->pid, $rmn--, $results->hash->{stuff});
          utf8::encode($sal);
          $c->write($sal => shift->begin);
          },
    sub {
          shift->pass($rmn); # 0 => end
          },
    sub {
      $c->finish("\n");
    }
    );
};

app->start;

__DATA__
@@ migrations
-- 1 up
CREATE TABLE app_test (id TEXT UNIQUE, stuff TEXT);
INSERT INTO app_test (id, stuff) VALUES (generate_series(1,30000),'');
UPDATE app_test SET stuff='I ♥ Mojolicious!: # ' || id;
-- 1 down
DROP TABLE app_test;