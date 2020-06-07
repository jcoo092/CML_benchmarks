#!/usr/bin/python

"""This program shows `hyperfine` benchmark results as a histogram."""

import argparse
import json
import numpy as np
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("file", help="JSON file with benchmark results")
parser.add_argument("--title", help="Plot title")
parser.add_argument("--bins", help="Number of bins (default: auto)")
parser.add_argument(
    "--type", help="Type of histogram (*bar*, barstacked, step, stepfilled)"
)
args = parser.parse_args()

with open(args.file) as f:
    results = json.load(f)["results"]

commands = [b["command"] for b in results]
all_times = [b["times"] for b in results]

t_min = np.min(list(map(np.min, all_times)))
t_max = np.max(list(map(np.max, all_times)))

bins = int(args.bins) if args.bins else "auto"
histtype = args.type if args.type else "bar"

plt.hist(
    all_times, label=commands, bins=bins, histtype=histtype, range=(t_min, t_max),
)
plt.legend(prop={"family": ["Source Code Pro", "Fira Mono", "Courier New"]})

plt.xlabel("Time [s]")
if args.title:
    plt.title(args.title)

plt.show()
