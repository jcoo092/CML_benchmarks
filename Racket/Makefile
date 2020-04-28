# Makefile to handle compilation of Racket programs to executables
# and run the benchmarks via hyperfine

# For Racket, the .rkt files are converted to executables using the
# `raco exe` command that comes with Racket installations.

# List the names of each file
names ::= montecarlopi whispers commstime linalg selecttime spawn
bench_names ::= bench_montecarlopi bench_whispers bench_commstime bench_linalg bench_selecttime bench_spawn

# Relevant directories
compiled_dir ::= ./compiled
benches_dir ::= ./benchmarks
exes_dir ::= ./executables

# The following is done on advice of the GNU Make manual's Makefile
# Conventions chapter, specifically ch 16.3 (as of 28 April 2020)
RACO = raco

.PHONY: all bench_all clean bench_montecarlopi

##################################################

# Commands for building each of the programs

define racket_make =
$(RACO) make $^
endef

define racket_compile =
$(RACO) exe -o $@ $^
endef

all: $(names)

### I'm moderately certain that, since the below all follow the exact
### same template, I should be able to specify them all with a static
### pattern rule, but I can't quite figure out how to do it.
	
$(compiled_dir)/commstime_rkt.zo: commstime.rkt
	$(racket_make)
	
$(exes_dir)/commstime: $(compiled_dir)/commstime_rkt.zo
	$(racket_compile)
	
$(compiled_dir)/linalg_rkt.zo: linalg.rkt
	$(racket_make)
	
$(exes_dir)/linalg: $(compiled_dir)/linalg_rkt.zo
	$(racket_compile)
	
$(compiled_dir)/montecarlopi_rkt.zo: montecarlopi.rkt
	$(racket_make)

$(exes_dir)/montecarlopi: $(compiled_dir)/montecarlopi_rkt.zo
	$(racket_compile)

$(compiled_dir)/selecttime_rkt.zo: selecttime.rkt
	$(racket_make)
	
$(exes_dir)/selecttime: $(compiled_dir)/selecttime_rkt.zo
	$(racket_compile)

$(compiled_dir)/spawn_rkt.zo: spawn.rkt
	$(racket_make)
	
$(exes_dir)/spawn: $(compiled_dir)/spawn_rkt.zo
	$(racket_compile)
	
$(compiled_dir)/whispers_rkt.zo: whispers.rkt
	$(racket_make)
	
$(exes_dir)/whispers: $(compiled_dir)/whispers_rkt.zo
	$(racket_compile)
	
##################################################

# Commands for running hyperfine to benchmark each program
# Unfortunately, because each program takes different parameters,
# I can't simply defined a nice canned recipe like for compliation.
# Instead, I attempt to address it with target specific variables.

# They below were taken from
# https://www.cmcrossroads.com/article/gnu-make-escaping-walk-wild-side
# on 28 April 2020.  My thanks to that blog post's author.
comma := ,
space := 
space += 
spaces-to-commas = $(subst $(space),$(comma),$1)

# An arbitrarily chosen selection of powers of two for the escalating
# iteration count.  This is applied universally across the benchmarks.
ITERATIONS = 1 2 4 8 #32 128 512 1024 16384

# For most programs, this is the number of threads to be used (it is
# written this way because it is a parameter to hyperfine).  For Select
# Time it is instead the number of channels to use.
THREADS = 2 4 8 16

# Since this part will be common to all benchmarking invocations
# I define it as a separate variable
hypw3 = hyperfine -w 3 --export-markdown $(benches_dir)/$@_$$i.md

# iter_command is redefined by each individual benchmarking process
# This permits me to use the one for loop definition, but customise
# the executed command
iter_command = echo $$i
bench_commstime : iter_command = $(hypw3) --parameter-list num_threads "$(spaces-to-commas $(THREADS))" "$< $$i {num_threads}"
bench_linalg : iter_command = $(hypw3) --parameter-list vecs_size "$(VECTORS)" "$< vector $$i {vecs_size}"
bench_montecarlopi : iter_command = $(hypw3) --parameter-list num_threads "$(spaces-to-commas $(THREADS))" "$< $$i {num_threads}"
bench_selecttime : iter_command = $(hypw3) --parameter-list num_chans "$(spaces-to-commas $(THREADS))" "$< $$i {num_chans}"
bench_spawn : iter_command = $(hypw3) --parameter-list num_threads "$(spaces-to-commas $(THREADS))" "$< $$i {num_threads}"
bench_whispers : iter_command = $(hypw3) --parameter-list num_threads "$(spaces-to-commas $(THREADS))" "$< ring $$i {num_threads}"

define for_iters =
	for i in $(ITERATIONS); do\
		$(iter_command); \
	done
endef

bench_all: $(bench_names)

bench_commstime: $(exes_dir)/commstime
	$(for_iters)
	
# Size of vectors or matrix rows/columns for linalg
VECTORS = 2 3 4 8 32 128 512

bench_linalg: $(exes_dir)/linalg
	$(for_iters)

bench_montecarlopi: $(exes_dir)/montecarlopi
	@echo threads $(THREADS)
	@echo spc-to-com $(spaces-to-commas $(THREADS))
	$(for_iters)

bench_selecttime: $(exes_dir)/selecttime
	$(for_iters)

bench_spawn: $(exes_dir)/spawn
	$(for_iters)
	
bench_whispers: $(exes_dir)/whispers
	$(for_iters)
	
##################################################

# Implement a 'clean' command
clean:
	-rm $(exes_dir)/*
	-rm $(compiled_dir)/*
