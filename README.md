# Mojolicious-Plugin-RestartableDelay
A Mojolicious Helper to dinamically restart steps adding them to the Mojo::IOLoop singleton

Helper looks like this:

```perl
helper restartable_delay => sub {
  my $c=shift;
  my $cb = pop;
  my @steps = @_;
  Mojo::IOLoop::Delay->new->steps(
    @steps,
    sub {
      my ($d, $more) = @_;
      if ($more) {$c->restartable_delay(@steps,$cb)} else {$cb->(@_)}
    }
  );
};
```

You call the helper with an array of steps and a final callback, normaly to render results.

The last step (before the callback) has to return a true value if you want a new set of steps to be generated.

The synapsis will be something like

```perl
my $rmn = 100;
  $c->restartable_delay(
    sub {
          $c->pg->db->query(
            'select * from app_test where id=?', $rmn => shift->begin);
          },
    sub {
          my ($d, $err, $results) = @_;
          # do something with $results->hash->...
          $rmn--;
          $d->pass($rmn); # 0 => end
          },
    sub {
      $c->render(text => $sal);
    }
    );
```

If you git cloned this repository, you will find a working example application. Just remember you need to have a postgresql database named "test" created.

There is also a basic test that retrieves 50 records both blocking and non-blocking. It should pass with

```perl
./pg_nb2.pl test
```
The app is heavily based on examples of Mojo::Pg written by sri and starts by generating an indexed table with 30K records (I ♥ Mojolicious!: # 1, etc).

If you run the app as a daemon, you can try to read for instance 10k records accesing to:

```perl
http://localhost:3000/blocking/10000
```
That should take several seconds depending on your system.

Besides each one of the 10K records, you will find same information like timestamp, pid of the daemon (allways de same), and pid of the Mojo::Pg daemon that actually retrieved the information.

During the download, you can verify that it is actually blocking trying to access from another browse tab to '/', that will not start until the blocking get is completed.

Now you can try to do same reading with the non-blocking version:

```perl
http://localhost:3000/non-blocking/10000
```
That will take longer, but you will notice that its actually non-blocking

In real life situations, I think it could be useful whenever you have to process a request without blocking the controller and that request is not 100% defined until execution time. For instance if you need to receive a POST with a JSON array and have to do some processing repeatedly with each member of the array, then there is not an easy way to solve it with Mojo::IOLoop::Dealy because you don't actually know how many steps you have to do.

