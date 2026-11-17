"""Hit each edge once per second for N seconds and print one line per tick."""
import sys, time, urllib.request, urllib.error
secs = int(sys.argv[1]) if len(sys.argv) > 1 else 20
ports = [8081, 8082, 8083]
ok = bad = 0
for _ in range(secs):
    cells = []
    for p in ports:
        try:
            r = urllib.request.urlopen(f"http://127.0.0.1:{p}/", timeout=2)
            cells.append(r.read().decode().strip()); ok += 1
        except urllib.error.HTTPError as e:
            cells.append(e.read().decode().strip()); bad += 1
        except Exception as e:
            cells.append(f"ERR :{p} {e.__class__.__name__}"); bad += 1
    codes = " ".join(c.split()[0] for c in cells)
    print(f"{time.strftime('%H:%M:%S')} [probe] {codes} | {cells[0]}", flush=True)
    time.sleep(1)
print(f"[probe] summary: {ok} ok, {bad} errors ({100*bad/(ok+bad):.0f}% 5xx)")
