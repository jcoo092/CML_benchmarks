# CML_benchmarks
The code and other assorted files pertaining to my attempts to benchmark parallel Concurrent ML (CML) processing in a handful of languages.  Concurrent ML is an approach to concurrent programming originally devised by (now-Professor) [John Reppy](https://www.cs.uchicago.edu/people/profile/john-h-reppy/) for his doctoral thesis.

NB:  This README is very much incomplete.  I plan to expand it more when I actually have finished most of the programming work.  Also, while I certainly would appreciate advice on the best use of a given language, I may or may not actually implement it here.  Since I am not overly familiar with any of the languages involved, there is an extra (implicit) test of the languages with regards to which is best for allowing non-expert users derive good performance from them.  Thus, while you are free to raise an issue suggesting an improvement and I certainly will listen to what you have to say, I don't guarantee that I will actually incorporate that into my programs.  I also **won't** be accepting any pull requests from other people for the time being.

The end goal of this work is to select a language with a CML implementation (whether it calls it that or not) for my purposes of testing that approach against more traditional approaches with regards to certain Stereo Vision algorithms.  To perform this test, I am writing a variety of small programs that test various relevant aspects of the languages and their CML implementations.

Currently, I am considering four languages (in alphabetical order):  Guile Scheme, MLton, OCaml and Racket (both Typed and regular).  These were the four languages I could identify which apparently have full (or pretty close to full) support for *parallel* CML, and met a number of other criteria.

## CML vs Communicating Sequential Processes
In recent times, there has been quite an explosion of interest in Communicating Sequential Processes (CSP), likely largely driven by Go's inclusion of channels and goroutines as part of its core.  You should note that CML is *not* equivalent to CSP.  Arguably, in a practical sense CML is a superset of CSP.  While CSP implementations do typically have synchronous channels and message passing etc, CML takes it further and makes synchronisation itself a full value in the language (with 'events' in Reppy's parlance).  This is similar to how most modern programming languages take a leaf out of functional programming and make functions themselves full values that can be passed around like other variables, i.e. incorporate higher-order functions.

CML is comprehensively explained in Reppy's book *Concurrent Programming in ML*.

## Exemplar programs
Each sub-repository contains implementations of six separate small programs (or will do, once its finished) that are intended to test one or more aspects of the language and its CML implementation.  They are mostly focused on testing the speed of various aspects of CML communication and processing, with two exceptions:  Linear Algebra and Monte Carlo Pi.

The concept of these programs has largely been sourced from the paper [*Parallel concurrent ML* by Reppy, Russo and Xiao](https://doi.org/10.1145/1596550.1596588); and Chalmers' CPA [*Language Shootout*](https://github.com/kevin-chalmers/cpa-lang-shootout).  Specifically, Communications Time, Monte Carlo Pi and Select Time were derived from the latter, while Spawn is derived from the former.  Whispers and Linear Algebra are original to this work (though neither is ground-breaking in the slightest).  Each test program is briefly described below.

### Communications Time
Communications Time is intended to measure the time taken to perform a reasonably simple amount of communication.  Four processing elements with distinct behaviours are spawned, and combined via channels to produce the natural numbers in sequence.

### Linear Algebra
A simple test of the language's capabilities with respect to linear algebra.  Linear algebra is often central to, or at least very useful in, computer vision processes -- especially vector and matrix multiplication.  This program merely generates random vectors/matrices and multiplies them together, with the results of that then used as inputs to next iteration after suitable adjustment to ensure that the values of the matrices remain within a target bound (e.g. 0-256).

This program has three modes:  vector, matrix and mixed, which perform vector-vector, matrix-matrix and vector-matrix multiplication, respectively.

### Monte Carlo Pi
This program is used to test the efficacy of a language's multicore support.  A Monte Carlo process is used to estimate pi in a fairly typical pattern seen frequently elsewhere, but the test is run multiple times with a greater and greater number of threads.  The change in the time taken to finish the computation provides some suggestion of the speed-up (or slow-down) the language is capable of when using multithreading.

### Select Time
Select Time is a particularly simple benchmark, which in its original form merely involves timing how long it takes a processing element to receive a message over one of a number of channels, with the channel in question randomly selected.  In this work, however, the selection includes offering to send over a number of channels, too.  The number of channels involved is varied, as an inefficient implementation of selection may have a worse-than-linear increase in time taken to select over channels.

### Spawn
This also is a relatively simple test.  A trivial child thread is created, and the parent merely waits on the child to terminate.  Both the total time for the process, as well as the time specifically spent waiting for termination, are measured.  This provides some evidence for the efficiency of handling multi-threading.  Importantly, where possible the child thread is directed to be scheduled onto a different processor than the parent.  Moreover, a greater number of children are spawned than there are hardware threads available on the given processors, to ensure that there is some over-saturation of the cores.

### Whispers
In its basic form, the Ring of Whispers is simply a large number of processes, each with an associated channel, formed into a uni-directional ring (i.e. a large digraph that forms a cycle), so that each process can receive a message from exactly one other process, and send a message to exactly one, \emph{different}, process.  A message is passed into one of the processes, and then the time taken for the message to traverse the entire ring and return to the first process measured.  The main wrinkle of this beyond that seen in Communications Time is that this involves a much greater number of simultaneously-active threads.

Potential variants include Grid of Whispers, where the processes are arranged logically into a grid, connected in a four-neighbourhood, either by a bi-directional channel, or two uni-directional channels with one pointing in each direction;  and Kn of Whispers (Kn is standard notation for the complete graph of n nodes).} where every process is connected to every other process, again by either one bi-directional channel or two uni-directional channels.

## Benchmarking process
Benchmarking in this repository is performed using the [hyperfine](https://github.com/sharkdp/hyperfine) command-line program.  The choice to use a command-line tool, instead of one built into/supplied with each language was made to ensure the best possible comparability.  Generally speaking, benchmarking and profiling tools for a given language tend to be focused on assisting developers working in that language to improve their programs.  Furthermore, they may make assumptions about the language, which probably won't be reasonable in other languages.  Thus, a language-neutral benchmarking approach is required.
