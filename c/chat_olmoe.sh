#!/bin/bash
# Launch OLMoE-1B-7B chat, memory-safe: hard RAM cap + swap disabled for this
# process so it can't hang the whole system again, even if something misbehaves.
# Override any default via env var, e.g.:  MAX_NEW=600 ./chat_olmoe.sh
set -e
cd "$(dirname "$0")"

SNAP_DIR="${SNAP_DIR:-/home/tony/models/olmoe_i8}"
MEMORY_MAX="${MEMORY_MAX:-10G}"
MAX_NEW="${MAX_NEW:-300}"
PILOT="${PILOT:-0}"   # measured faster than PILOT=1 once CACHE=64 gives a ~94% hit rate --
                       # the prefetch thread has little disk-wait left to hide and just
                       # competes with compute for CPU on this 8-core machine
TEMP="${TEMP:-0.7}"
NUCLEUS="${NUCLEUS:-0.95}"
CTX="${CTX:-4096}"
# 64 = OLMoE's total experts/layer, so the cache holds ALL of them -- no eviction,
# no thrashing (this engine doesn't dedupe repeated expert picks during prefill,
# so a smaller cache causes constant reload storms; see conversation history).
# ~6GB cache + ~1.8GB dense =~ 7.8GB peak, hence MEMORY_MAX=10G above for margin.
CACHE="${CACHE:-64}"

exec systemd-run --user --scope -p MemoryMax="$MEMORY_MAX" -p MemorySwapMax=0 --collect \
  -- bash -c "SNAP='$SNAP_DIR' CHAT=1 MAX_NEW=$MAX_NEW PILOT=$PILOT TEMP=$TEMP NUCLEUS=$NUCLEUS CTX=$CTX ./olmoe $CACHE 8"
