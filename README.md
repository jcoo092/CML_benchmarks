# A Comparative Benchmarking of Various Concurrent ML Implementations

NB:  This README is incomplete.  I plan to expand it more when I actually have finished most of the programming work.  Also, while I certainly would appreciate advice on the best use of a given language, I may or may not actually implement it here.  Since I am not overly familiar with any of the languages involved, there is an extra (implicit) test of the languages with regards to which is best for allowing non-expert users derive good performance from them.  Thus, while you are free to raise an issue suggesting an improvement and I certainly will listen to what you have to say, I don't guarantee that I will actually incorporate that into my programs.  **I also won't be accepting any pull requests from other people for the time being, for the same reason.**

The repository hosts the sourcecode and other assorted files pertaining to my attempts to benchmark parallel Concurrent ML (CML) processing in a handful of languages.  Concurrent ML is an approach to concurrent programming originally devised by (now-Professor) [John Reppy](https://www.cs.uchicago.edu/people/profile/john-h-reppy/) for his doctoral thesis.  The [original language](http://cml.cs.uchicago.edu/) was created as an extension [Standard ML of New Jersey](https://www.smlnj.org/)(SML/NJ), but the name 'Concurrent ML' [has come to refer to the concepts involved at least as much as the original implementation](https://medium.com/@asolove/concurrent-ml-has-a-branding-problem-ce0286eab598).

The end goal of this work is to select a language with a CML implementation (whether it calls it that or not) for my purpose of testing that approach against more traditional methods with regards to certain [Stereo Vision](https://en.wikipedia.org/wiki/Computer_stereo_vision) algorithms.  To perform this test, I am writing a variety of small programs that test various relevant aspects of the languages and their CML implementations.

So far, I have considered two languages (in alphabetical order):  [MLton](http://www.mlton.org/Home) and [Racket](https://racket-lang.org/) (both [Typed](https://docs.racket-lang.org/ts-reference/index.html) and regular).  These were selected as 'representative samples' of two language families that I could identify which apparently have full (or pretty close to full) support for *parallel* CML, and met a number of other criteria.  MLton, as a newer version of SML/NJ includes a port of [CML](http://www.mlton.org/ConcurrentML)  and Racket includes [channels and events](https://docs.racket-lang.org/guide/concurrency.html) in its standard library -- unlike the other languages, though, Racket's threads do not spread across multiple cores automatically, necessitating the use of [Places](https://docs.racket-lang.org/guide/parallelism.html#%28tech._place%29) also.  Other candidates that were originally intended to be included were Guile Scheme with the [Fibers library](https://github.com/wingo/fibers) and OCaml with the [Events](https://ocaml.org/releases/4.10/htmlman/libref/Event.html) module.  Both ended up being excluded, primarily because of time constraints, but also because they were expected to be under-performers to the above.  Guile is explicitly intended as a scripting language to be embedded into other programs, and to generate proper compiled stand-alone executables looked to be a complicated process that might not work well (maybe, I never got a chance to investigate it properly; while mainline OCaml is actually still not a multicore language (as at the time of writing).  There is an ongoing Multicore OCaml project underway, but when checked it did not seem to support the Events module.

I investigated many other languages, libraries and frameworks, but (with one exception) could not find any others that met all my requirements.  In particular, no other CML implementation could be found that was truly parallel, actively maintained, and available.  The one exception to this was the [Manticore programming language](https://www.cs.rit.edu/~mtf/manticore/), which comes with a parallel implementation of CML built-in.  I chose to exclude it as, on the surface at least, it appears to be extremely similar to MLton, but MLton works on a greater number of processor architectures.  Thus, I felt addressing both would be an unhelpful duplication of efforts.  [Hopac](https://github.com/Hopac/Hopac), for [F#](https://fsharp.org/), also came close, but has received little substantive maintenance in the past few years.  I hope to include both of them as well as Guile and OCaml in this repository in the future.

## CML vs Communicating Sequential Processes

There has been quite an explosion of interest in Hoare's Communicating Sequential Processes (CSP) during the past few years, likely largely driven by Go's inclusion of channels and goroutines as part of its core.  You should note that CML is *not* equivalent to CSP.  Arguably, in a practical sense CML is a superset of CSP.  While CSP implementations do typically have synchronous channels and message passing etc, CML takes it further and makes synchronisation itself a full value in the language (with 'events' in Reppy's parlance).  This is similar to how most modern programming languages take a leaf out of functional programming and make functions themselves full values that can be passed around like other variables, i.e. incorporate higher-order functions.

CML is explained comprehensively in Reppy's book [*Concurrent Programming in ML*](https://www.worldcat.org/title/concurrent-programming-in-ml/oclc/444440035?referer=di&ht=edition).

The 'events' introduced by Reppy with CML are in fact used in *at least one* of the benchmark programs for each language, and further are expected to be used in later work, so a language that merely implements CSP, e.g. D, Go or Nim, all of which include synchronous channels in their major distributions, is not relevant to this particular work.

## Exemplar programs

Each sub-repository contains implementations of six separate small programs (or will do, once this effort is finished) that are intended to test one or more aspects of the language and its CML implementation.  They are mostly focused on testing the speed of various aspects of CML communication and processing, with two exceptions:  Linear Algebra and Monte Carlo π.

The concept of these programs has largely been sourced from the paper [*Parallel concurrent ML* by Reppy, Russo and Xiao](https://doi.org/10.1145/1596550.1596588); and Chalmers' [*CPA Language Shootout*](https://github.com/kevin-chalmers/cpa-lang-shootout).  Specifically, Communications Time, Monte Carlo π and Select Time were derived from the latter, while Spawn is derived from the former.  Whispers and Linear Algebra are original to this work (though neither is ground-breaking in the slightest).  Each test program is briefly described below.

### Communications Time

Communications Time is intended to measure the time taken to perform a reasonably simple amount of communication.  Four processing elements with distinct behaviours are spawned, and combined via channels to produce the natural numbers in sequence.

### Linear Algebra

A simple test of the language's capabilities with respect to linear algebra.  Linear algebra is often central to, or at least very useful in, computer vision processes -- especially vector and matrix multiplication.  This program merely generates random vectors/matrices and multiplies them together, with the results of that then used as inputs to next iteration after suitable adjustment to ensure that the values of the matrices remain within a target bound (e.g. 0-256).

This program has three modes:  vector, matrix and mixed, which perform vector-vector, matrix-matrix and vector-matrix multiplication, respectively.

### Monte Carlo π

This program is used to test the efficacy of a language's multicore support.  A Monte Carlo process is used to estimate π in a fairly typical pattern seen frequently elsewhere, but the test is run multiple times with a greater and greater number of threads.  The change in the time taken to finish the computation provides some suggestion of the speed-up (or slow-down) the language is capable of when using multithreading.

### Select Time

Select Time is a particularly simple benchmark, which in its original form merely involves timing how long it takes a processing element to receive a message over one of a number of channels, with the channel in question randomly selected.  In this work, however, the selection includes offering to send over a number of channels, too.  The number of channels involved is varied, as an inefficient implementation of selection may have a worse-than-linear increase in time taken to select over channels.

### Spawn

This also is a relatively simple test.  A trivial child thread is created, and the parent merely waits on the child to terminate.  Both the total time for the process, as well as the time specifically spent waiting for termination, are measured.  This provides some evidence for the efficiency of handling multi-threading.  Importantly, where possible the child thread is directed to be scheduled onto a different processor than the parent.  Moreover, a greater number of children are spawned than there are hardware threads available on the given processors, to ensure that there is some over-saturation of the cores.

### Whispers

In its basic form, the Ring of Whispers is simply a large number of processes, each with an associated channel, formed into a uni-directional ring (i.e. a large digraph that forms a cycle), so that each process can receive a message from exactly one other process, and send a message to exactly one, *different*, process.  A message is passed into one of the processes, and then the time taken for the message to traverse the entire ring and return to the first process measured.  The main challenge of this program beyond that seen in Communications Time is that this involves a much greater number of simultaneously-active threads.

Potential variants include Grid of Whispers, where the processes are arranged logically into a grid, connected in a four-neighbourhood, either by a bi-directional channel, or two uni-directional channels with one pointing in each direction;  and Kn of Whispers (Kn is standard notation for the complete graph of n nodes) where every process is connected to every other process, again by either one bi-directional channel or two uni-directional channels.

## Benchmarking process

Benchmarking in this repository is performed using the [hyperfine](https://github.com/sharkdp/hyperfine) command-line program.  The choice to use a command-line tool, instead of one built into/supplied with each language was made to ensure the best possible comparability.  Generally speaking, benchmarking and profiling tools for a given language tend to be focused on assisting developers working in that language to improve their programs.  Furthermore, they may make assumptions about the language, which probably won't be reasonable in other languages.  Thus, a language-neutral benchmarking approach is required.

The precise details of the benchmarking process are yet to be determined.  Well-informed suggestions are welcome.  Prospectively, the system used will be switched to that of the [Computer Language Benchmarks Game](https://benchmarksgame-team.pages.debian.net/benchmarksgame/), found at [Debian's online git hosting](https://salsa.debian.org/benchmarksgame-team/benchmarksgame).
