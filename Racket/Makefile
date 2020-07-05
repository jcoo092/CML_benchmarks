# Makefile to handle compilation of Racket programs to executables
# and run the benchmarks via hyperfine.  Yes, this makefile is somewhat
# horrific, but it serves my purposes.  I have nevertheless attempted
# to make it as clean and straightforward as possible.  In particular,
# I have endeavoured to ensure that anything that is used in a rule or
# definition has already been defined further up in the file, with the
# exception of the `all` command, which is deliberately placed first so that
# it is the default command for `make`.

# For Racket, the .rkt files are converted to bytecode *_rkt.zo files
# using the `raco make` command, and then from there into regular
# executables using the `raco exe` command that comes with Racket 
# installations.

# Relevant directories
src_dir ::= ./src
# I don't like having `compiled` as a subdirectory of `src`, but 
# `raco make` doesn't really give me much of a choice in the matter.
compiled_dir ::= $(src_dir)/compiled
exes_dir ::= ./executables
benches_dir ::= ./benchmarks
memory_dir ::= ./memory

# List the names of each file
names ::= commstime linalg montecarlopi selecttime spawn whispers
rkt_zo_names ::= $(foreach name, $(names), $(compiled_dir)/$(name)_rkt.zo)
exe_names ::= $(foreach name, $(names), $(exes_dir)/$(name))
bench_names ::= $(foreach name, $(names), bench_$(name))
memory_names ::= $(foreach name, $(names), memory_$(name))

.PHONY: all bench_all $(bench_names) clean_all clean clean_bench memory_all $(memory_names)

##################################################

# Commands for building each of the programs

# The following is done on advice of the GNU Make manual's Makefile
# Conventions chapter, specifically ch 16.3 (as of 28 April 2020)
RACO = raco

define racket_make =
$(RACO) make $^
endef

define racket_compile =
$(RACO) exe -o $@ $^
endef

all: $(names)

### An issue here is that I need to do this silly thing where I make
### each of the program names essentially just a call to the static
### rule where the program name is preceded by the executables
### directory, which seems like a terrible idea, but I'm not sure how
### to work around it.

$(names) : % : $(exes_dir)/%
	make $(exes_dir)/$@

$(rkt_zo_names) : $(compiled_dir)/%_rkt.zo : $(src_dir)/%.rkt
	$(racket_make)

$(exe_names) : $(exes_dir)/% : $(compiled_dir)/%_rkt.zo | $(exes_dir)
	$(racket_compile)

##################################################

# Commands for running hyperfine to benchmark each program
# Unfortunately, because each program takes different parameters,
# I can't simply define a nice canned recipe like for compliation.
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

# A selection of powers of two for the escalating
# iteration count.  These start at one, and are multiplied by 2**6 each
# increase to derive the new number.
# This variable is applied universally across the benchmarks.
#ITERATIONS = 1 8 64 512 4096 #32768 262144 2097152 16777216
ITERATIONS = 1 64 4096 #262144 16777216

# For most programs, this is the number of threads to be used.  For 
# Select Time it is instead the number of channels to use.
# As with $(ITERATIONS), this starts at a base number, two, and then
# increases each time by multiplying the previous number by 2**3.
THREADS = 2 16 128 1024 8192 #65536 524288 4194304

# The number of warmups to use for hyperfine to perform each run.  I'm 
# defaulting to 2, as an arbitrarily chosen number, but using a 
# variable means that the number can be overridden on the command line.
WARMUPS = 2

# Size of vectors or matrix rows/columns for linalg.  These numbers were
# chosen pretty much entirely arbitrarily, but mostly biased towards
# smaller vectors & matrices, as I expect those to be more important
# for me later on.
VECTORS = 2 3 4 8 16 32 128 #512 2048 65536

# Options for the linear algebra program
LINALG_OPTS ::= vector matrix mixed

# Options for Whispers program
# Currently, because the latter two options aren't implemented in the 
# program they are commented out here.
WHISPERS_OPTS ::= ring #kn grid

benches_record_name = $(benches_dir)/$@_$$i
bench_commstime : benches_record_name = $(benches_dir)/$@
bench_linalg : benches_record_name = $(benches_dir)/$@\_$$j\_$$i
bench_whispers : benches_record_name = $(benches_dir)/$@\_$$j\_$$i

# Since this part will be common to all benchmarking invocations
# I define it as a separate variable
hypw3 = hyperfine -w $(WARMUPS) --export-markdown $(benches_record_name).md --export-csv $(benches_record_name).csv --export-json $(benches_record_name).json

# iter_command is redefined by each individual benchmarking process
# This permits me to use the one for loop definition, but customise
# the executed command
# Strictly speaking, the entry for bench_commstime isn't actually 
# needed.  I leave it here for completeness.
iter_command = echo $$i
bench_commstime : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_linalg : iter_command = $(hypw3) --parameter-list vecs_size "$(call spaces-to-commas,$(VECTORS))" "$< $$j $$i {vecs_size}"
bench_montecarlopi : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_selecttime : iter_command = $(hypw3) --parameter-list num_chans "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_chans}"
bench_spawn : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_whispers : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$j $$i {num_threads}"

define for_iters =
	for i in $(ITERATIONS); do\
		$(iter_command);\
	done
endef

bench_all: $(bench_names)
#bench_all: bench_commstime bench_montecarlopi bench_selecttime

# bench_commstime works differently from the others, since, at present
# at least, it only takes one parameter, meaning that hyperfine
# can handle everything without resorting to an external for loop.
bench_commstime: $(exes_dir)/commstime | $(benches_dir)
	$(hypw3) --parameter-list num_iters "$(call spaces-to-commas,$(ITERATIONS))" "$< {num_iters}"

# Note that this one is different from most of the others in that it
# requires an extra input, which requires both adapting the iter_command
# as well as wrapping for_iters with another for loop.  Unfortunately,
# to get things to work, I need to use a variable named j in the loop
# wrapping the one which uses the variable i...
#~ bench_linalg: $(exes_dir)/linalg | $(benches_dir)
#~ 	for j in $(LINALG_OPTS); do\
#~ 		$(for_iters);\
#~ 	done
	
bench_linalg:
	make bench_linalg1
	make bench_linalg2

bench_linalg1 : benches_record_name = $(benches_dir)/$@\_$$j\_$$i
bench_linalg1 : iter_command = $(hypw3) --parameter-list vecs_size "$(call spaces-to-commas,$(VECTORS))" "$< $$j $$i {vecs_size}"
bench_linalg1 : VECTORS = 2 3 4 8 16 32
bench_linalg1: $(exes_dir)/linalg | $(benches_dir)
	for j in $(LINALG_OPTS); do\
		$(for_iters);\
	done

bench_linalg2 : benches_record_name = $(benches_dir)/$@\_$$j\_$$i
bench_linalg2 : iter_command = $(hypw3) --parameter-list vecs_size "$(call spaces-to-commas,$(VECTORS))" "$< $$j $$i {vecs_size}"
bench_linalg2 : VECTORS = 128
bench_linalg2 : ITERATIONS = 1 64
bench_linalg2: $(exes_dir)/linalg | $(benches_dir)
	for j in $(LINALG_OPTS); do\
		$(for_iters);\
	done

bench_montecarlopi: $(exes_dir)/montecarlopi | $(benches_dir)
	$(for_iters)

bench_selecttime: $(exes_dir)/selecttime | $(benches_dir)
	$(for_iters)

#~ bench_spawn: $(exes_dir)/spawn | $(benches_dir)
#~ 	$(for_iters)

bench_spawn: $(exes_dir)/spawn | $(benches_dir)
	make bench_spawn1
	make bench_spawn2

bench_spawn1 : THREADS = 2 16 128 1024
bench_spawn1 : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_spawn1: $(exes_dir)/spawn | $(benches_dir)
	$(for_iters)

bench_spawn2 : THREADS = 8192
bench_spawn2 : ITERATIONS = 1 64
bench_spawn2 : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$i {num_threads}"
bench_spawn2: $(exes_dir)/spawn | $(benches_dir)
	$(for_iters)

# This has the same issues as bench_linalg - see the comment there.
#~ bench_whispers: $(exes_dir)/whispers | $(benches_dir)
#~ 	for j in $(WHISPERS_OPTS); do\
#~ 		$(for_iters); \
#~ 	done

bench_whispers: $(exes_dir)/whispers | $(benches_dir)
	make bench_whispers1
	make bench_whispers2

bench_whispers1 : benches_record_name = $(benches_dir)/$@\_$$j\_$$i
bench_whispers1 : THREADS = 2 16 128 1024
bench_whispers1 : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$j $$i {num_threads}"
bench_whispers1: $(exes_dir)/whispers | $(benches_dir)
	for j in $(WHISPERS_OPTS); do\
		$(for_iters); \
	done

bench_whispers2 : benches_record_name = $(benches_dir)/$@\_$$j\_$$i
bench_whispers2 : THREADS = 8192
bench_whispers2 : ITERATIONS = 1 64
bench_whispers2 : iter_command = $(hypw3) --parameter-list num_threads "$(call spaces-to-commas,$(THREADS))" "$< $$j $$i {num_threads}"
bench_whispers2: $(exes_dir)/whispers | $(benches_dir)
	for j in $(WHISPERS_OPTS); do\
		$(for_iters); \
	done
	
##################################################

# Some basic scripting to use `/usr/bin/time` to get
# an estimate of the total memory used

memory_all: $(memory_names)

memory_command = /usr/bin/time -v -o $(memory_dir)/

memory_commstime: $(exes_dir)/commstime | $(memory_dir)
	$(memory_command)commstime.txt $< 4096
	
memory_linalg: $(exes_dir)/linalg | $(memory_dir)
	$(memory_command)linalg_matrix_64_128.txt $< matrix 64 128
	$(memory_command)linalg_matrix_4096_32.txt $< matrix 4096 32
	$(memory_command)linalg_mixed_64_128.txt $< mixed 64 128
	$(memory_command)linalg_mixed_4096_32.txt $< mixed 4096 32
	$(memory_command)linalg_vector_64_128.txt $< vector 64 128
	$(memory_command)linalg_vector_4096_32.txt $< vector 4096 32
	
memory_montecarlopi: $(exes_dir)/montecarlopi | $(memory_dir)
	$(memory_command)montecarlopi.txt $< 4096 8192
	
memory_selecttime: $(exes_dir)/selecttime | $(memory_dir)
	$(memory_command)selecttime.txt $< 4096 8192
	
memory_spawn: $(exes_dir)/spawn | $(memory_dir)
	$(memory_command)spawn_64_128.txt $< 64 8192
	$(memory_command)spawn_4096_32.txt $< 4096 1024
	
memory_whispers: $(exes_dir)/whispers | $(memory_dir)
	$(memory_command)whispers_ring_64_128.txt $< ring 64 8192
	$(memory_command)whispers_ring_4096_32.txt $< ring 4096 1024

##################################################

# Implement a 'clean' command.  This just clears out the compiled
# bytecode files and executables.  Everything else is an important part
# of the build process and shouldn't be removed.
clean:
	-rm $(exes_dir)/*
	-rm $(compiled_dir)/*
	
# Remove all the benchmarking output files.  This is kept separate from the 
# `clean` command above, since it might not be desirable to remove them at the
# same time at the other output files.
clean_bench:
	-rm $(benches_dir)/*
	
# Remove all the benchmarking output files.  This is kept separate from the 
# `clean` command above, since it might not be desirable to remove them at the
# same time at the other output files.
clean_memory:
	-rm $(memory_dir)/*
	
# A convenience command to execute both of the above cleaning commands
clean_all:
	@make clean
	@make clean_bench
	@make clean_memory

##################################################

# Rules to ensure that the required sub-directories are in fact extant.
# This approach is based upon answers to the following Stack Overflow
# question:  https://stackoverflow.com/q/1950926

$(exes_dir):
	@mkdir -p $(exes_dir)
	
$(benches_dir):
	@mkdir -p $(benches_dir)
	
$(memory_dir):
	mkdir -p $(memory_dir)
