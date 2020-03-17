montecarlopi: montecarlopi.sml montecarlopi.mlb
	mlton -prefer-abs-paths true -show-def-use montecarlopi.du montecarlopi.mlb

mcp_bench_iters: montecarlopi
	hyperfine -w 3 -L ITERATIONS 1048576,4194304,16777216,67108864 './montecarlopi {ITERATIONS} 4'

mcp_bench_threads: montecarlopi
	hyperfine -w 3 -L THREADS 1,2,4,8,16,32,128,512,1024 './montecarlopi 16777216 {THREADS}'
