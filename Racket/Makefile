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

.PHONY: all bench_all clean bench_montecarlopi bench_whispers bench_commstime bench_linalg bench_selecttime bench_spawn

##################################################

# Commands for building each of the programs

# The following is done on advice of the GNU Make manual's Makefile
# Conventions chapter, specifically ch 16.3 (as of 28 April 2020)
RACO = raco

define racket_make =
$(RACO) make $^
endef

define racket_compile =
$(RACO) exe -l -o $@ $^
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

# The below were compiled from the GNU Make manual, chapter 6.2,
# the StackOverflow post at https://stackoverflow.com/q/7525589 and
# https://www.cmcrossroads.com/article/gnu-make-escaping-walk-wild-side
# all of which were accessed on 28 April 2020.
# My thanks to all of the involved authors.
comma := ,
nullstring :=
space := $(nullstring) # end of the line
spaces-to-commas = $(subst $(space),$(comma),$(strip $(1)))

# An arbitrarily chosen selection of powers of two for the escalating
# iteration count.  This is applied universally across the benchmarks.
#ITERATIONS = 1 128 512 1024 16384 65536 524288
ITERATIONS = 1 16384 65536 524288 2097152 16777216

# For most programs, this is the number of threads to be used (it is
# written this way because it is a parameter to hyperfine).  For Select
# Time it is instead the number of channels to use.
#THREADS = 2 4 8 16 32 64 128 512 1024 8192
THREADS = 2 64 128 512 1024 8192 16384 65536

# The number of warmups to use for each run.  I'm defaulting to 5, as
# a fairly arbitrarily chosen number, but doing it this way means that
# the number can be overridden on the command line.
WARMUPS = 5

benches_record_name = $(benches_dir)/$@_$$i

# Since this part will be common to all benchmarking invocations
# I define it as a separate variable
hypw3 = hyperfine -w $(WARMUPS) --export-markdown $(benches_record_name).md --export-csv $(benches_record_name).csv

# iter_command is redefined by each individual benchmarking process
# This permits me to use the one for loop definition, but customise
# the executed command
iter_command = echo $$i
bench_commstime : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_linalg : iter_command = $(hypw3) --parameter-list vecs_size "$(call spaces-to-commas,$(VECTORS))" "$< vector $$i {vecs_size}"
bench_montecarlopi : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_selecttime : iter_command = $(hypw3) --parameter-list num_chans "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_chans}"
bench_spawn : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_whispers : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< ring $$i {num_threads}"

define for_iters =
	@for i in $(ITERATIONS); do\
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
