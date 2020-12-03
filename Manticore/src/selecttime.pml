fun sender iterations chans length cv = let   
    fun do_send 0 = CVar.signal cv
      | do_send iter = let
          val next_iter = iter - 1
          val randNum = Rand.inRangeInt(0, length)
      in
          PrimChan.send (Array.sub(chans, randNum), iter);
          do_send next_iter
      end
in
    do_send iterations
end

fun receiver recvEvents = let
    val msg = Event.select recvEvents
in
    (* TextIO.print("Received message " ^ (Int.toString(msg)) ^ ".\n"); *)
    Print.print("Received message " ^ (Int.toString(msg)) ^ ".\n");
    receiver recvEvents
end

fun experiment iterations num_chans = let
    (* val _ = MLton.Random.srand (valOf (MLton.Random.useed ())) *)
    val cv = CVar.new ()
    val chans = List.tabulate(num_chans, fn _ => PrimChan.new ())
    val recvEvents = List.map (fn ch => PrimEvent.recvEvt ch) chans
    val _ = spawn (fn () => receiver recvEvents)
    val sendThrd = spawn (fn () => sender iterations
									  (Array.fromList chans) num_chans
									  cv)
in
    (* PrimEvent.sync (CML.joinEvt sendThrd); *)
    CVar.wait cv
    Print.print("Select Time completed successfully.\n")
end

val args = CommandLine.arguments()
val iterations = Option.valOf (Int.fromString(List.nth(args, 0)))
val num_chans = Option.valOf (Int.fromString(List.nth(args, 1)))
val _ = RunSeq.run (fn () => experiment iterations num_chans)
