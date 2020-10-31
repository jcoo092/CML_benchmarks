fun ID (in_ch : int CML.chan) (out_ch : int CML.chan) : unit = let
    val msg = (CML.recv in_ch)
in
    CML.send (out_ch, msg);
    ID in_ch out_ch
end

fun prefix (N : int) (in_ch : int CML.chan) (out_ch : int CML.chan) : unit = let
in
    CML.send (out_ch, N);
    ID in_ch out_ch
end

fun  successor (in_ch : int CML.chan) (out_ch : int CML.chan) : unit = let
    val msg = CML.recv in_ch
    val msgp = msg + 1
in
    CML.send (out_ch, msgp);
    successor in_ch out_ch
end

fun consumer _ 0 = ()
  | consumer (in_ch : int CML.chan) (count : int) : unit = let
      val next_count = count - 1
      val msg = CML.recv in_ch
  in
      consumer in_ch next_count
  end

(* Ideally I would use a wrap combinator on the below, but to keep consistency with Racket I don't. *)
fun delta (in_ch : int CML.chan) (out1 : int CML.chan) (out2 : int CML.chan) : unit = let
    val msg = CML.recv in_ch
in
    CML.send (out1, msg);
    CML.send (out2, msg);
    delta in_ch out1 out2
end

fun commstime (iterations : int) = let
    val a = CML.channel ()
    val b = CML.channel ()
    val c = CML.channel ()
    val d = CML.channel ()
    val consThd = CML.spawn (fn () => consumer d iterations)
    val _ = CML.spawn (fn () =>
                          delta b c d)
    val _ = CML.spawn (fn () => successor c a)
    val _ = CML.spawn (fn () => prefix 0 a b)
in
    CML.joinEvt consThd
end

fun experiment (iterations : int) : unit = let
    val prefixJoin = commstime iterations
in
    CML.sync prefixJoin;
    TextIO.print("Communications Time completed succesfully.\n")
end

local
    val args = CommandLine.arguments()
    val iterations = valOf (Int.fromString(List.nth(args, 0)))
in
val _ = RunCML.doit (fn () => (experiment iterations), NONE)
end
