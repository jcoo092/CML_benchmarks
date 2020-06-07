# NOTA BENE

The scripts contained in this folder have been copied directly from the [Hyperfine repository](https://github.com/sharkdp/hyperfine), on the 7th of June 2020, by cloning from the `master` branch when its HEAD pointed to the [commit with hash '8de77e136a497ad304ceb74097a468d05b9a3163'](https://github.com/sharkdp/hyperfine/commit/8de77e136a497ad304ceb74097a468d05b9a3163).  They were **not** written as part of the CML Benchmarks project.  All credit for the scripts should be given to the Hyperfine contributors.  They are included in this repository for the sole purpose of ensuring the maximum possible level of reproducibility of the CML Benchmarks work, by providing the precise scripts used to produce any reported statistics or charts.  If you are not attempting to reproduce the CML Benchmarks work, then it is *extremely strongly* recommended that you refer to the Hyperfine repository for the latest versions of the scripts rather than using the ones here.

Many thanks to David Peter ([sharkdp](https://github.com/sharkdp)) and [all other Hyperfine contributors](https://github.com/sharkdp/hyperfine/graphs/contributors) for their efforts!

## The original README follows:

This folder contains scripts that can be used in combination with hyperfines `--export-json` option.

### Example:

``` bash
> hyperfine 'sleep 0.020' 'sleep 0.021' 'sleep 0.022' --export-json sleep.json
> python plot_benchmark_results.py sleep.json
```

### Pre-requisites

To make these scripts work, you will need to install `numpy` and `matplotlib`. Install them via
your package manager or `pip`:

```bash
pip install numpy matplotlib  # pip3, if you are using python3
```
