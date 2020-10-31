structure Commstime = struct

	fun ID (in_ch : int PrimChan.chan) (out_ch : int PrimChan.chan) : unit = let
		val msg = (PrimChan.recv in_ch)
	in
		PrimChan.send (out_ch, msg);
		ID in_ch out_ch
	end

	fun prefix (N : int) (in_ch : int PrimChan.chan) (out_ch : int PrimChan.chan) : unit = 
		(PrimChan.send (out_ch, N);
		ID in_ch out_ch)

	fun  successor (in_ch : int PrimChan.chan) (out_ch : int PrimChan.chan) : unit = let
		val msg = PrimChan.recv in_ch
		val msgp = msg + 1
	in
		PrimChan.send (out_ch, msgp);
		successor in_ch out_ch
	end

	fun consumer stop _ 0 = CVar.signal stop
	  | consumer stop (in_ch : int PrimChan.chan) (count : int) : unit = let
		  val next_count = count - 1
		  val msg = PrimChan.recv in_ch
	  in
		  (* Print.printLn("Consumed " ^ (Int.toString msg)); *)
		  consumer stop in_ch next_count
	  end

	(* Ideally I would use a wrap combinator on the below, but to keep consistency with Racket I don't. *)
	fun delta (in_ch : int PrimChan.chan) (out1 : int PrimChan.chan) (out2 : int PrimChan.chan) : unit = let
		val msg = PrimChan.recv in_ch
	in
		PrimChan.send (out1, msg);
		PrimChan.send (out2, msg);
		delta in_ch out1 out2
	end

	fun commstime (iterations : int) = let
		val a = PrimChan.new ()
		val b = PrimChan.new ()
		val c = PrimChan.new ()
		val d = PrimChan.new ()
		val stopCV = CVar.new ()
	in
		spawn (consumer stopCV d iterations);
		spawn (delta b c d);
		spawn (successor c a);
		spawn (prefix 0 a b);
		stopCV
	end

	fun experiment iterations = let
		val stopCV = commstime iterations
	in
		CVar.wait stopCV;
		Print.print("Communications Time completed succesfully.\n")
	end
	
end

val args = CommandLine.arguments()
val iterations = Option.valOf (Int.fromString(List.nth(args, 0)))
val _ = RunSeq.run (fn () => Commstime.experiment iterations)
