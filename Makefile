FIBER_C_BASE=third_party/fiber-c
LIBMPROMPT_BASE=third_party/libmprompt
LIBMPEFF=$(LIBMPROMPT_BASE)/out/release/libmpeff.a
LIBHANDLER_BASE=third_party/libhandler
LIBHANDLER=$(LIBHANDLER_BASE)/out/$(CC)-amd64-pc-linux-gnu/release/libhandler.a
LIBSEFF_BASE=third_party/libseff
LIBSEFF=$(LIBSEFF_BASE)/output/lib/libseff.a

CC=clang-21
CXX=clang++-21
CFLAGS=-Wno-unknown-attributes -I$(FIBER_C_BASE)/inc -std=c23
LFLAGS=-fuse-ld=mold
LIBMPROMPT_LFLAGS=-flto

.PHONY: all
all: itersum

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

.PHONY: clean
clean:
	rm -f *.a *.o
	rm -f *.out
