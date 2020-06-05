# MLton language CML benchmarks

Directory containing the files for the MLton language benchmarks.  This contains both the source file for each benchmark, as well as a Makefile to build the programs and run the benchmarks, plus some directories which are also used in the process.  The 'src' directory contains the input source code files; the 'mlbs' directory basis declaration files and .du files output from the compilation process (which are mostly relevant for development purposes); the 'executables' directory contains the executable programs; and the 'benchmarks' directory contains the outputs from the benchmarking process.  Please note that the benchmarking process is still very much subject to change in the future, so for now it is a 'best effort', and may not provide especially useful results.  Also, you probably will want to check the following variables inside the Makefile to ensure you won't start a benchmark that'll take way too long for you:  `ITERATIONS`, `THREADS`, `WARMUPS`, `VECTORS`, `LINALG_OPTS` AND `WHISPERS_OPTS`, 

## Compiling these programs

The easy way to compile the programs is to use the provided makefile, assuming that the MLton compiler invocation `mlton`, is on the PATH.  The easiest way to do that is to run `make $(PROG)` inside the CML_benchmarks/MLton folder where `$(PROG)` stands for the name of the particular program to be benchmarked (in each case, this is identical to its source file, without the .sml extension).  For example, to compile the Monte Carlo Pi simulation program, use:

``` Bash
make montecarlopi
```

Note that this is unlikely to work on Windows, since (to the best of my knowledge) there isn't a good Makefile program for it.  It *should* work when using Powershell on *Nix, I expect.  Note that the Makefile used here has been written targeting, and only tested with, GNU Make, so if you use a different program there's a chance you could have some incompatibilites.  Also, you will see a few lines about "entering the exectuables directory" or some such.  You can safely ignore those -- they're a by-product of a hack I use in the Makefile to ensure that you can simply specify the program's name without anything else in front of it, but still have the program put into the right place.

Alternatively, you can use simply `mlton src/$(PROG)` to compile the individual executable program.  For the purposes of merely running the programs, rather than performing development work, this probably should be sufficient, though the extra compiler flags added by the Makefile don't extend the compilation time by any great amount.

## Executing these programs

The 'official' way to execute the programs is to compile as above, and then run them using the 'executables' in the executables directory.  For example, assuming that you have already run `make executables $(PROG)` as described above, in this case substituting 'montecarlopi' for $(PROG), for Bash you should be able to use (assuming that your current directory is the same one this README is found in):

``` Bash
./executables/montecarlopi $(NUM_ITERATIONS) $(NUM_THREADS)
```

(see below for more on the parameters to the program)

These programs *should* be standalone, and not have any dependencies, though that point hasn't been tested as of yet.

## Running the benchmarks
Details of the benchmarks are written into the Makefile.  Each benchmarking process can be executed by using the following command, where `$(PROG)` has the same meaning as above:

``` Bash
make bench_$(PROG)
```

Currently, the benchmarks each use the excellent `hyperfine` [command-line tool]() to orchestrate the benchmarks and record the results.  The output files from the process can be found in the 'benchmarks' folder.  If desired, you can override the controlling parameters for each benchmark by modifying the Makefile variables listed at the end of the first paragraph of this document, either within the Makefile itself, or by overriding them via the command line invocation.  As an example of the latter, to run the Monte Carlo Pi benchmarks using only iteration counts of 1 and 4, you could use:

``` Bash
make bench_montecarlopi ITERATIONS='1 4'
```

## Parameters to each program

Communications Time takes the number of iterations only (this might change in the future).

Linear Algebra (currently the filename is shortened to linalg) takes, in order, the particular style of linear algebra to run, the number of iterations, and the size of a vector, or the size of the rows and columns of a square matrix.   The type of tensors to use currently can be selected from amongst vector, matrix and mixed, which are respectively specified as the strings `vector`, `matrix` and `mixed`.  Vector performs vector addition and multiplication between two same-sized vectors (one is transposed each iteration for the multiplication, and the first row of the resulting matrix used as an input to the next iteration).  Matrix performs matrix addition and multiplication between two square matrices.  Mixed performs matrix-vector multiplication, for both row and column vectors.  Note that with the MLton version at present, the tensor type strings **must** be specified exactly as-is.  Any capitalisation will cause the program to fail.

Monte Carlo Pi takes, in order, the number of iterations and the number of threads to use.

Select Time takes, in order, the number of iterations and the number of channels for each of the sender and receiver to select over.

Spawn takes, in order, the number of iterations and the number of threads to spawn in each iteration.

Whispers takes, in order, the particular style of whispering to run, the number of iterations, and the number whispering agents.  The style of whispering currently can be selected from amongst ring, complete graph and 4-neighbour-grid, which are respectively specified as the strings `ring`, `kn` and `grid`.  In the case of grid specifically, the program also as arguments takes the width and height, respectively, of the grid - these default to 50 each if not provided.  A count of the whisperers must still be provided, but is ignored.  Note that with the MLton version at present, the whispering style strings **must** be specified exactly as-is.  Any capitalisation will cause the program to fail.
