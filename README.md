# Core stack switching experiments

Some experiments with segmented stacks, virtual memory mapped stacks,
and stack copying.

## Running experiments

The fiber interface and the libraries used to implement its backends
are stored in submodules, which must be retrieved first:

```console
$ git submodule update --init
$ make all
```

Note, `libhandler` (used to evaluate stack copying) is a bit clever
about the naming its output directory, so you may need to adjust the
configuration variable `LIBHANDLER` to suit your platform.

## Future work

* I/O-bound benchmarks
* Lazy stack copying strategy (e.g. Java/Loom)
