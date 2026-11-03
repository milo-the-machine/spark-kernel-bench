#!/usr/bin/env python3
"""Steady C-N load against an OpenAI-compatible endpoint for the loaded soak (T1b). Stdlib only.
   load.py <api_root> <model> <concurrency> <minutes> <out.json>"""
import json, random, sys, threading, time, urllib.request

api, model, conc, mins, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), float(sys.argv[4]), sys.argv[5]
deadline = time.time() + mins * 60
lock = threading.Lock(); stats = {"ok": 0, "err": 0, "completion_tokens": 0, "errors": []}
words = ("kernel spark memory network fabric decode prefill tensor ring switch cache token model latency "
         "throughput driver module reboot soak queue batch stream rail bandwidth").split()


def worker(i):
    rnd = random.Random(i)
    while time.time() < deadline:
        n = rnd.randint(1500, 6000)
        prompt = " ".join(rnd.choice(words) for _ in range(n)) + "\n\nSummarise the text above in five bullet points."
        body = {"model": model, "messages": [{"role": "user", "content": prompt}], "max_tokens": 512, "temperature": 0.7,
                "chat_template_kwargs": {"thinking": False}}
        req = urllib.request.Request(api.rstrip("/") + "/v1/chat/completions", data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json"})
        try:
            r = json.load(urllib.request.urlopen(req, timeout=600))
            with lock:
                stats["ok"] += 1; stats["completion_tokens"] += r.get("usage", {}).get("completion_tokens", 0)
        except Exception as e:  # noqa: BLE001
            with lock:
                stats["err"] += 1
                if len(stats["errors"]) < 20: stats["errors"].append(f"{time.strftime('%H:%M:%S')} {type(e).__name__}: {str(e)[:160]}")
            time.sleep(5)


t0 = time.time()
ts = [threading.Thread(target=worker, args=(i,), daemon=True) for i in range(conc)]
[t.start() for t in ts]; [t.join() for t in ts]
stats.update({"kind": "load", "concurrency": conc, "minutes": round((time.time() - t0) / 60, 1),
              "tok_s_avg": round(stats["completion_tokens"] / max(1, time.time() - t0), 1)})
json.dump(stats, open(out, "w"), indent=1); print(json.dumps({k: v for k, v in stats.items() if k != "errors"}))
