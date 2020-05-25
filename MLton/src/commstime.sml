fun ID _ _ 0 = ()
  | ID (in_ch : int CML.chan) (out_ch : int CML.chan) (count : int) : unit = let
      val next_count = count - 1
      val msg = (CML.recv in_ch)
  in
      (CML.send (out_ch, msg));
      ID in_ch out_ch next_count
  end

fun prefix (N : int) (in_ch : int CML.chan) (out_ch : int CML.chan) (count : int) : unit = let
    val next_count = count - 1
in
    (CML.send (out_ch, N));
    ID in_ch out_ch count
end

fun successor _ _ 0 = ()
  | successor (in_ch : int CML.chan) (out_ch : int CML.chan) (count : int) : unit = let
      val next_count = count - 1
      val msg = (CML.recv in_ch)
      val msgp = msg + 1
  in
      (CML.send (out_ch, msgp));
      successor in_ch out_ch next_count
  end

fun consumer _ 0 = ()
  | consumer (in_ch : int CML.chan) (count : int) : unit = let
      val next_count = count - 1
      val msg = (CML.recv in_ch)
  in
      (* TextIO.print ("Received: " ^ (Int.toString (msg)) ^ "\n"); *)
      consumer in_ch next_count
  end

fun delta _ _ _ 0 = ()
  | delta (in_ch : int CML.chan) (out1 : int CML.chan) (out2 : int CML.chan) (count : int) : unit = let
      val next_count = count - 1
      val msg = (CML.recv in_ch)
      val send1e = CML.wrap (CML.sendEvt (out1, msg), fn _ => CML.send(out2, msg))
      val send2e = CML.wrap (CML.sendEvt (out2, msg), fn _ => CML.send(out1, msg))

  in
      CML.select [send1e, send2e];
      delta in_ch out1 out2 next_count
  end

fun commstime (iterations : int) : unit = let
    val a = CML.channel ()
    val b = CML.channel ()
    val c = CML.channel ()
    val d = CML.channel ()
    val consumer = CML.spawn (fn () => consumer d iterations)
    val delta = CML.spawn (fn () =>
                              delta b c d
                                    iterations)
    val successor = CML.spawn (fn () =>
                                  successor c a iterations)
in
    CML.spawn (fn () => prefix 0 a b iterations);
    TextIO.print ("Job's done!\n")
end

fun experiment (iterations : int) () : unit = let
    val dummy = 5
in
    commstime iterations;
    TextIO.print("Communications Time completed succesfully.\n")
end

local
    val args = CommandLine.arguments()
    val iterations = valOf (Int.fromString(List.nth(args, 0)))
in
val _ = RunCML.doit ((experiment iterations), NONE)
(* val _ = TextIO.print("Communications Time completed succesfully.\n") *)
end
