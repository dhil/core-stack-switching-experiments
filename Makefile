FIBER_C_BASE=third_party/fiber-c
LIBMPROMPT_BASE=third_party/libmprompt
LIBMPEFF=$(LIBMPROMPT_BASE)/out/release/libmpeff.a
LIBHANDLER_BASE=third_party/libhandler
LIBHANDLER=$(LIBHANDLER_BASE)/out/$(CC)-amd64-pc-linux-gnu/release/libhandler.a
LIBSEFF_BASE=third_party/libseff
LIBSEFF=$(LIBSEFF_BASE)/output/lib/libseff.a

CC=clang-21
CXX=clang++-21
CFLAGS=-Wno-unknown-attributes -I$(FIBER_C_BASE)/inc -std=c23 -O3
LFLAGS=-fuse-ld=mold
LIBMPROMPT_LFLAGS=-flto

.PHONY: all
all: itersum treesum sieve

$(LIBMPEFF): $(LIBMPROMPT_BASE)
	cd $(LIBMPROMPT_BASE); \
	mkdir -p out/release; \
	cd out/release; \
	cmake ../.. -DCMAKE_CXX_COMPILER=$(CXX) -DCMAKE_C_COMPILER=$(CC) -DMP_USE_C=ON; \
	make

$(LIBHANDLER): $(LIBHANDLER_BASE)
	cd $(LIBHANDLER_BASE); \
	./configure --cc=$(CC) --cxx=$(CXX); \
	make depend; \
	make staticlib VARIANT=release

$(LIBSEFF): $(LIBSEFF_BASE)
	cd $(LIBSEFF_BASE); \
	make CC=$(CC) CXX=$(CXX) LD=mold BUILD=release output/lib/libseff.a

libmprompt_fiber.o: src/libmprompt_fiber.c $(LIBMPEFF)
	$(CC) -c $(CFLAGS) -I$(LIBMPROMPT_BASE)/include src/libmprompt_fiber.c

libhandler_fiber.o: src/libhandler_fiber.c $(LIBHANDLER)
	$(CC) -c $(CFLAGS) -I$(LIBHANDLER_BASE)/inc src/libhandler_fiber.c

libseff_fiber.o: src/libseff_fiber.c $(LIBSEFF)
	$(CC) -c $(CFLAGS) -I$(LIBSEFF_BASE)/src src/libseff_fiber.c

.PHONY: itersum
itersum: $(FIBER_C_BASE)/examples/itersum.c libmprompt_fiber.o libhandler_fiber.o libseff_fiber.o
	$(CC) $(LIBMPROMPT_LFLAGS) $(LFLAGS) $(CFLAGS) libmprompt_fiber.o $(FIBER_C_BASE)/examples/itersum.c -o itersum_libmprompt.out $(LIBMPEFF)
	$(CC) $(LFLAGS) $(CFLAGS) libhandler_fiber.o $(FIBER_C_BASE)/examples/itersum.c -o itersum_libhandler.out $(LIBHANDLER)
	$(CC) $(LFLAGS) $(CFLAGS) libseff_fiber.o $(FIBER_C_BASE)/examples/itersum.c -o itersum_libseff.out $(LIBSEFF)

.PHONY: treesum
treesum: $(FIBER_C_BASE)/examples/treesum.c libmprompt_fiber.o libhandler_fiber.o libseff_fiber.o
	$(CC) $(LIBMPROMPT_LFLAGS) $(LFLAGS) $(CFLAGS) libmprompt_fiber.o $(FIBER_C_BASE)/examples/treesum.c -o treesum_libmprompt.out $(LIBMPEFF)
	$(CC) $(LFLAGS) $(CFLAGS) libhandler_fiber.o $(FIBER_C_BASE)/examples/treesum.c -o treesum_libhandler.out $(LIBHANDLER)
	$(CC) $(LFLAGS) $(CFLAGS) libseff_fiber.o $(FIBER_C_BASE)/examples/treesum.c -o treesum_libseff.out $(LIBSEFF)

.PHONY: sieve
sieve: $(FIBER_C_BASE)/examples/sieve.c libmprompt_fiber.o libhandler_fiber.o libseff_fiber.o
	$(CC) $(LIBMPROMPT_LFLAGS) $(LFLAGS) $(CFLAGS) libmprompt_fiber.o $(FIBER_C_BASE)/examples/sieve.c -o sieve_libmprompt.out $(LIBMPEFF)
	$(CC) $(LFLAGS) $(CFLAGS) libhandler_fiber.o $(FIBER_C_BASE)/examples/sieve.c -o sieve_libhandler.out $(LIBHANDLER)
	$(CC) $(LFLAGS) $(CFLAGS) libseff_fiber.o $(FIBER_C_BASE)/examples/sieve.c -o sieve_libseff.out $(LIBSEFF)

.PHONY: bench-itersum
bench-itersum: itersum
	hyperfine -L N 10000 './itersum_libmprompt.out {N}' './itersum_libhandler.out {N}' './itersum_libseff.out {N}'
	hyperfine -L N 100000 './itersum_libmprompt.out {N}' './itersum_libhandler.out {N}' './itersum_libseff.out {N}'
	hyperfine -L N 1000000 './itersum_libmprompt.out {N}' './itersum_libhandler.out {N}' './itersum_libseff.out {N}'

.PHONY: bench-treesum
bench-treesum: treesum
	hyperfine -L N 21 './treesum_libmprompt.out {N}' './treesum_libhandler.out {N}' './treesum_libseff.out {N}'
	hyperfine -L N 22 './treesum_libmprompt.out {N}' './treesum_libhandler.out {N}' './treesum_libseff.out {N}'
	hyperfine -L N 23 './treesum_libmprompt.out {N}' './treesum_libhandler.out {N}' './treesum_libseff.out {N}'

.PHONY: bench-sieve
bench-sieve: sieve
	hyperfine -L N 1000 './sieve_libmprompt.out -q {N}' './sieve_libhandler.out -q {N}' './sieve_libseff.out -q {N}'
	hyperfine -L N 4000 './sieve_libmprompt.out -q {N}' './sieve_libhandler.out -q {N}' './sieve_libseff.out -q {N}'
	hyperfine -L N 8000 './sieve_libmprompt.out -q {N}' './sieve_libhandler.out -q {N}' './sieve_libseff.out -q {N}'

.PHONY: clean
clean:
	rm -f *.a *.o
	rm -f *.out
