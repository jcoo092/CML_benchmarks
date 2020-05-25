fun sender iterations chans length = let
    val lengthAsWord = Word.fromInt length
    fun do_send 0 = ()
      | do_send iter = let
          val next_iter = iter - 1
          val randNum = Word.toInt ((MLton.Random.rand ()) mod lengthAsWord)
      in
          TextIO.print ("randNum: " ^ (Int.toString(randNum))  ^ ".\n");
          CML.send (Vector.sub(chans, randNum), iter);
          do_send next_iter
      end
in
    do_send iterations
end

fun receiver recvEvents = let
    val msg = CML.select recvEvents
in
    TextIO.print("Received message " ^ (Int.toString(msg)) ^ ".\n");
    receiver recvEvents
end

fun selecttime iterations num_chans = let
    val chans = List.tabulate(num_chans, fn _ => CML.channel ())
    val recvEvents = List.map (fn ch => CML.recvEvt ch) chans
    val _ = CML.spawn (fn () => receiver recvEvents)
in
    CML.spawn (fn () => sender iterations (Vector.fromList chans) num_chans);
    TextIO.print("Select Time successfully completed!\n")
end

fun experiment iterations num_chans () = let
    val _ = MLton.Random.srand (valOf (MLton.Random.useed ()))
in
    selecttime iterations num_chans
end

local
    val args = CommandLine.arguments()
    val iterations = valOf (Int.fromString(List.nth(args, 0)))
    val num_chans = valOf (Int.fromString(List.nth(args, 1)))
in
val _ = RunCML.doit ((experiment iterations num_chans), NONE)
end
