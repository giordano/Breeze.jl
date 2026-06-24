#!/bin/bash

set -euo pipefail

julia --project -e 'using Pkg; Pkg.instantiate()'

### A100
FEW_FREQUENCIES=(1005 1110 1200 1305 1410)
MANY_FREQUENCIES=(1005 1020 1035 1050 1065 1080 1095 1110 1125 1140 1155 1170 1185 1200 1215 1230 1245 1260 1275 1290 1305 1320 1335 1350 1365 1380 1395 1410)

MIN_POWER_CAP=150
MAX_POWER_CAP=300
POWER_CAPS=(${MIN_POWER_CAP} 175 200 225 250 275 ${MAX_POWER_CAP})

### RTX PRO 6000 Blackwell Server Edition
FEW_FREQUENCIES=(1005 1200 1402 1605 1800 2002 2205 2430)
MANY_FREQUENCIES=(1005 1200 1402 1605 1800 2002 2205 2430)

MIN_POWER_CAP=300
MAX_POWER_CAP=600
POWER_CAPS=(${MIN_POWER_CAP} 350 400 450 500 550 ${MAX_POWER_CAP})

function reset_gpus() {
    sudo nvidia-smi --power-limit=${MAX_POWER_CAP}
    sudo nvidia-smi --reset-gpu-clocks
}

# Reset GPUs on exit
trap reset_gpus INT QUIT TERM EXIT

# Reset GPUs before starting, for good measure
reset_gpus

for frequency in ${FEW_FREQUENCIES[@]}; do
    for power in ${POWER_CAPS[@]}; do
        sudo nvidia-smi --lock-gpu-clocks=${frequency},${frequency}
        sudo nvidia-smi --power-limit=${power}
        rm -f benchmark_results.json
        rm -f energy.json
        julia --color=yes --project run_benchmarks.jl --device GPU --size "1152x1152x512" --warmup_steps 4 --time_steps 20
        mv benchmark_results.json benchmark_results-${frequency}-${power}.json
        mv energy.json energy-${frequency}-${power}.json
    done
done
