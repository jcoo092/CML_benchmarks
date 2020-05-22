# Racket language CML benchmarks

Directory containing the files for the Racket language benchmarks.  This contains both the source file for each benchmark, as well as a Makefile to build the programs and run the benchmarks, plus some directories which are also used in the process.  The 'compiled' directory contains the output from the `raco make` command for each program; the 'executables' directory contains the executable Racket files produced by the `raco exe` command, and the 'benchmarks' directory contains the outputs from the benchmarking process.  Please note that the benchmarking process is still very much subject to change in the future, so for now it is a 'best effort', and may not provide especially useful results.  Also, you probably will want to check the following variables inside the Makefile to ensure you won't start a benchmark that'll take way too long for you:  `ITERATIONS`, `THREADS`, `WARMUPS`, `VECTORS`, `LINALG_OPTS` AND `WHISPERS_OPTS`, 

## Compiling these programs

The easy way to compile the programs is to use the provided makefile.  The easiest way to do that is to run `make bench_$(PROG)` where `$(PROG)` stands for the name of the particular program to be benchmarked.  This has the effect of compiling the programs appropriately *before* starting the benchmarking process.  For example, to compile the Monte Carlo Pi simulation program and run its default benchmarks in Bash (assuming your current directory is the same Racket directory containing this file), use:

``` Bash
make bench_montecarlopi
```

Note that this is unlikely to work on Windows, since (to the best of my knowledge) there isn't a good Makefile program for it.  It *should* work when using Powershell on *Nix, I expect.  Note that the Makefile used here has been written targeting, and only tested with, GNU Make, so if you use a different program there's a chance you could have some incompatibilites.

Alternatively, you can use `make executables/$(PROG)` to compile the individual executable program.  This is considered to be an imperfect system, since you have to type 'executables' before each name.  Alternatively, you can type `make all` to compile each of the programs in turn.  I am yet to find a way to deal with that appropriately yet, however.

## Executing these programs

The 'official' way to execute the programs is to compile as above, and then run them using the 'executables' in the executables directory.  For example, assuming that you have already run `make executables $(PROG)` as described above, in this case substituting 'montecarlopi' for $(PROG), for Bash you should be able to use (assuming that your current directory is the same one this README is found in):

``` Bash
./executables/montecarlopi $(NUM_ITERATIONS) $(NUM_THREADS)
```

(see below for more on the parameters to the program)

These programs are the full-blown executables that apparently include an embedding of the core Racket runtime inside themselves.  It would be preferable to use the launcher option of `raco exe`, which just creates what are essentially shell scripts that use a Racket local installation, but for reasons unknown, that option seems to prevent the command line arguments to the programs from being received.  Since it is intended that these programs are compiled and run on a system with a proper Racket installation, relying on there being a proper Racket installation on the host system isn't really an issue, but using the full executables was the only way I could find to simulate regular executable programs as produced by other languages.

### Executing these programs - alternative

An alternative way to execute these programs is to run them directly from the Racket scripts with the Racket interpreter.  E.g. to execute the MonteCarloPi program on Windows (where this particular one has been developed), you would use:

``` Powershell
$(PATH TO RACKET EXECUTABLE)\Racket.exe -tm .\montecarlopi.rkt $(NUM ITERATIONS) $(NUM THREADS)
```

where `$(PATH TO RACKET EXECUTABLE)` is the location of the Racket executable file (on the current computer it is "C:\Program Files\Racket"); `$(NUM ITERATIONS)` is the desired number of iterations for the program to run; and $(NUM THREADS) is the number of threads to be use.  `-tm` are flags to the Racket executable - the details aren't important here, just know they need to be included.  The other programs will all follow much the same pattern.  Of course, if the Racket executable is on the PATH, then there is no need to specify the path to it in the command.

So, e.g. if the Racket executable is on the path and you are using Bash (or Zsh, or something else fairly equivalent), you would instead run it simply as:

``` Bash
racket -tm ./montecarlopi.rkt $(NUM ITERATIONS) $(NUM THREADS)
```

This probably will have roughly comparable performance to the technique described above, but that technique has the major advantage of consistency with the behaviour of the programs produced by the other languages.  At present, you will see an error message printed after the program finishes when using this approach.  Something about main not being required, or somesuch.  Best as I can tell, you can ignore that.

## Parameters to each program

Communications Time takes the number of iterations only (this might change in the future).

Linear Algebra (currently the filename is shortened to linalg) takes, in order, the particular style of linear algebra to run, the number of iterations, and the size of a vector, or the size of the rows and columns of a square matrix.   The style of whispering currently can be selected from amongst vector, matrix and mixed, which are respectively specified as the strings `vector`, `matrix` and `mixed`.  Vector performs vector addition and multiplication between two same-sized vectors (one is transposed each iteration for the multiplication, and the first row of the resulting matrix used as an input to the next iteration).  Matrix performs matrix addition and multiplication between two square matrices.  Mixed performs matrix-vector multiplication, for both row and column vectors.

Monte Carlo Pi takes, in order, the number of iterations and the number of threads to use.

Select Time takes, in order, the number of iterations and the number of channels for each of the sender and receiver to select over.

Spawn takes, in order, the number of iterations and the number of threads to spawn in each iteration.

Whispers takes, in order, the particular style of whispering to run, the number of iterations, and the number whispering agents.  The style of whispering currently can be selected from amongst ring, ~~complete graph and 4-neighbour-grid~~, which are respectively specified as the strings `Ring`, ~~`Kn` and `Grid`~~.  ~~In the case of grid specifically, the program also as arguments takes the width and height, respectively, of the grid - these default to 50 each if not provided.  A count of the whisperers must still be provided, but is ignored.~~  **NB:**  At the present point in time, kn and grid are not implemented, and are entirely commented-out in the source code.  This is because, with the extra complication of the communicating threads being wrapped inside places, and thus communication necessarily occuring through places, development was taking a long time.  Thus, they were de-prioritised for the time being.  Should Racket prove competetive on the other tests, they will be implemented to complete the comparison.  Likewise, even if Racket isn't chosen for my later work, I hope to come back and finish them at some point.
