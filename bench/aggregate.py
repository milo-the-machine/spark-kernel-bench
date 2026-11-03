#!/usr/bin/env python3
"""Aggregate receipts/<ARM>/ into one comparison table (markdown + JSON). Numbers come only from receipt files.
   aggregate.py [receipts_dir]"""
import json, glob, os, statistics as st, sys

RD = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "receipts")
ORDER = ["K0", "S0", "S1", "S1x", "S2"]


def jl(path):
    out = []
    if os.path.exists(path):
        for l in open(path):
            l = l.strip()
            if l.startswith("{"):
                try:
                    out.append(json.loads(l))
                except Exception:
                    pass
    return out


def jf(path):
    try:
        return json.load(open(path))
    except Exception:
        return None


def rng(xs, nd=1):
    xs = [x for x in xs if x is not None]
    if not xs:
        return "—"
    m = st.mean(xs)
    return f"{m:.{nd}f} ({min(xs):.{nd}f}–{max(xs):.{nd}f})" if len(xs) > 1 else f"{m:.{nd}f}"


arms = sorted([d for d in os.listdir(RD) if os.path.isdir(os.path.join(RD, d)) and d[:2] in ("K0", "S0", "S1", "S2")],
              key=lambda a: ORDER.index(a.split("-")[0]) if a.split("-")[0] in ORDER else 99)
res = {}
for a in arms:
    p = os.path.join(RD, a); r = {"arm": a}
    facts = [jf(f) for f in sorted(glob.glob(f"{p}/facts-spark*.json"))]
    facts = [f for f in facts if f]
    if facts:
        r["kernel"] = sorted({f["kernel"] for f in facts}); r["driver"] = sorted({f["driver"] for f in facts})
        r["xid_this_boot"] = sum(int(f.get("xid_this_boot") or 0) for f in facts)
        r["memavail_gib_boot"] = round(st.mean(int(f["memavail_kib"]) / 1048576 for f in facts), 1)
        r["memtotal_gib"] = round(st.mean(int(f["memtotal_kib"]) / 1048576 for f in facts), 1)
        r["kho_off"] = all("kho=off" in f["cmdline"] for f in facts)
    al = [jf(f) for f in glob.glob(f"{p}/alloc-spark*.json")]
    al = [x for x in al if x]
    if al:
        r["alloc_gib"] = min(x.get("allocated_gib", x.get("max_alloc_gib", 0)) for x in al)
        r["alloc_secs"] = round(max(x["secs"] for x in al), 1)
    rd = jl(f"{p}/rdma.jsonl")
    for hog in (0, 100):
        bw = [x["bw_avg_gbps"] for x in rd if f"hog{hog} " in x["label"] and x["test"] == "ib_write_bw" and "bw_avg_gbps" in x]
        lat = [x["lat_typ_us"] for x in rd if f"hog{hog} " in x["label"] and x["test"] == "ib_write_lat" and "lat_typ_us" in x]
        r[f"rdma_write_gbps_hog{hog}"] = rng(bw, 2); r[f"rdma_lat_us_hog{hog}"] = rng(lat, 2)
        r[f"rdma_fail_hog{hog}"] = sum(1 for x in rd if f"hog{hog} " in x["label"] and (x["rc"] != 0 or x.get("err")))
    nc = [x for x in jl(f"{p}/nccl.jsonl") if x.get("kind") == "summary"]
    for nn in (2, 4):
        for hog in (0, 100):
            s = [x for x in nc if x["world"] == nn and f"hog{hog}-" in x["label"]]
            r[f"nccl_n{nn}_hog{hog}_Gbps"] = rng([x["peak_busbw_Gbps"] for x in s if x["status"] == "ok"], 1)
            r[f"nccl_n{nn}_hog{hog}_fail"] = sum(1 for x in s if x["status"] != "ok")
    ln = os.path.join(p, "lane")
    rj = jf(f"{ln}/ready.json"); r["lane_ready_s"] = rj and rj.get("ready_s")
    bdir = glob.glob(f"{ln}/battery/*/")
    if bdir:
        b = bdir[0]
        for ph in ("c1", "c16"):
            d = jf(f"{b}{ph}.json")
            if d and d.get("summary"):
                r[f"{ph}_agg_tok_s"] = rng([x["agg_tok_s"] for x in d["summary"]["reps"]], 1)
                r[f"{ph}_ttft_s"] = rng([x["ttft_mean_s"] for x in d["summary"]["reps"]], 3)
        d = jf(f"{b}prefill.json"); r["prefill"] = d and d.get("summary")
        d = jf(f"{b}mixed_warm.json"); r["mixed_warm"] = d and d.get("summary")
    for nm in ("noninf-vs-base8", "noninf-vs-K0"):
        d = jf(f"{ln}/{nm}.json")
        if d:
            r[nm] = {k: d.get(k) for k in ("verdict", "pass", "p99_abs_dlogp", "max_abs_dlogp", "positions") if k in d} or d
    lb = jl(f"{p}/llama-bench.jsonl")
    for x in lb:
        key = f"llama_{'pp' if x.get('n_prompt') else 'tg'}{x.get('n_prompt') or x.get('n_gen')}@d{x.get('n_depth', 0)}"
        r[key] = round(x.get("avg_ts", 0), 2)
    for x in jl(f"{p}/gemm_membw.jsonl"):
        if x["kind"] == "gemm_bf16": r["gemm_bf16_tflops"] = x["peak_tflops"]
        if x["kind"] == "membw_copy": r["membw_GBs"] = x["median_GBs"]
    for lab in ("idle", "loaded"):
        d = jf(f"{p}/soak-{lab}-summary.json")
        if d: r[f"soak_{lab}"] = f"{d['minutes']} min, {d['resets']} resets, {d['unreachable_polls']} unreachable polls"
    us = jl(f"{p}/userns.jsonl")
    if us: r["userns"] = {f"{x['node']}:{x['check']}": x["result"] for x in us}
    res[a] = r

json.dump(res, open(os.path.join(RD, "aggregate.json"), "w"), indent=1)
keys = []
for r in res.values():
    for k in r:
        if k not in keys and k not in ("arm", "prefill", "mixed_warm", "userns", "noninf-vs-base8", "noninf-vs-K0"):
            keys.append(k)
print("| metric | " + " | ".join(a.split("-")[0] for a in res) + " |")
print("|---|" + "---|" * len(res))
for k in keys:
    print(f"| {k} | " + " | ".join(str(res[a].get(k, "—")) for a in res) + " |")
