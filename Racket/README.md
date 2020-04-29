# Racket language CML benchmarks

Directory containing the files for the Racket language benchmarks.  This contains both the source file for each benchmark, as well as a Makefile to build the programs and run the benchmarks, plus some directories which are also used in the process.  The 'compiled' directory contains the output from the `raco make` command for each program; the 'executables' directory contains the executable Racket files produced by the `raco exe` command, and the 'benchmarks' directory contains the outputs from the benchmarking process.

## Compiling these programs

The easy way to compile the programs is to use the provided makefile.  The easiest way to do that is to run `make bench_$(PROG)` where `$(PROG)` stands for the name of the particular program to be benchmarked.  This has the effect of compiling the programs appropriately *before* starting the benchmarking process.  For example, to compile the Monte Carlo Pi simulation program and run its default benchmarks in Bash (assuming your current directory is the same Racket directory containing this file), use:

``` Bash
make bench_montecarlopi
```

Note that this is unlikely to work on Windows, since (to the best of my knowledge) there isn't a good Makefile program for it.  It *should* work when using Powershell on *Nix, I expect.  Note that the Makefile used here has been written targeting, and only tested with, GNU Makefile, so if you use a different program there's a chance you could have some incompatibilites.

Alternatively, you can use `make executables/$(PROG)` to compile the individual executable program.  This is considered to be an imperfect system, since you have to type 'executables' before each name, and you can't (currently) use `make all` (which *should* also be the default when you just run `make`).  I am yet to find a way to deal with that appropriately yet, however.

## Executing these programs

The 'official' way to execute the programs is to compile as above, and then run them using the 'executables' in the executables directory.  For example, assuming that you have already run `make executables $(PROG)` as described above, substituting 'montecarlopi' for $(PROG), in Bash you should be able to use:

``` Bash
./executables/montecarlopi $(NUM_ITERATIONS) $(NUM_THREADS)
```

(see below for more on the parameters to the program)

These executables are actually just shell scripts generated using the launcher option of `raco exe`.  Full-blown executables (which nevertheless apparently still require a local Racket installation) can be created by Raco, but these are enormous, and actually seem to have a slower startup time than the ones produced by the launcher.  Since it is intended that these programs are compiled and run on a system with a proper Racket installation, relying on there being a proper Racket installation on the host system isn't really an issue.  So, between the apparently-better performance and smaller footprint of the 'programs' produced by the launcher, they are the chosen option here.

### Executing these programs - alternative

An alternative way to execute these programs is to run them directly from the Racket scripts with the Racket interpreter.  E.g. to execute the MonteCarloPi program on Windows (where this particular one has been developed), you would use:

``` Powershell
$(PATH TO RACKET EXECUTABLE)\Racket.exe -tm .\montecarlopi.rkt $(NUM ITERATIONS) $(NUM THREADS)
```

where `$(PATH TO RACKET EXECUTABLE)` is the location of the Racket executable file (on the current computer it is "C:\Program Files\Racket"); `$(NUM ITERATIONS)` is the desired number of iterations for the program to run; and $(NUM THREADS) is the number of CML threads required to be used.  `-tm` are flags to the Racket executable - the details aren't important here, just know they need to be included.  The other programs will all follow much the same pattern.  Of course, if the Racket executable is on the PATH, then there is no need to specify the path to it in the command.

So, e.g. if the Racket executable is on the path and you are using Bash (or Zsh, or something else fairly equivalent), you would instead run it simply as:

``` Bash
racket -tm ./montecarlopi.rkt $(NUM ITERATIONS) $(NUM THREADS)
```

This probably will have roughly comparable performance to the technique described above, but that technique has the major advantage of consistency with the behaviour of the programs produced by the other languages.

## Parameters to each program

Communications Time takes, in order, the number of iterations (this is likely to change in the future).

Linear Algebra (currently the filename is shortened to linalg) take, in order, the particular style of linear algebra to run, the number of iterations, and the size of a vector, or the size of the rows and columns of a square matrix.   The style of whispering currently can be selected from amongst vector, matrix and mixed, which are respectively specified as the strings `vector`, `matrix` and `mixed`.  Vector performs vector addition and multiplication between two same-sized vectors (one is transposed each iteration for the multiplication, and the first row of the resulting matrix used as an input to the next iteration).  Matrix performs matrix addition and multiplication between two square matrices.  Mixed performs matrix-vector multiplication, for both row and column vectors.

Monte Carlo Pi takes, in order, the number of iterations and the number of threads to use.

Select Time takes, in order, the number of iterations and the number of channels for each of the sender and receiver to select over.

Spawn takes, in order, the number of iterations and the number of threads to spawn in each iteration.

Whispers takes, in order, the particular style of whispering to run, the number of iterations, and the number whispering agents.  The style of whispering currently can be selected from amongst ring, complete graph and 4-neighbour-grid, which are respectively specified as the strings `ring`, `kn` and `grid`.  In the case of grid specifically, the program also as arguments takes the width and height, respectively, of the grid - these default to 50 each if not provided.  A count of the whisperers must still be provided, but is ignored.
