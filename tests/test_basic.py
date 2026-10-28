#!/usr/bin/env python3
"""Pure-function tests for tb-heal - no hardware required.

Run: python3 tests/test_basic.py
"""
import importlib.machinery
import importlib.util
import os
import sys

loader = importlib.util.spec_from_loader(
    "tb_heal",
    importlib.machinery.SourceFileLoader("tb_heal", os.path.join(
        os.path.dirname(__file__), "..", "tb-heal")))
tb = importlib.util.module_from_spec(loader)
loader.loader.exec_module(tb)

failures = []


def check(name, got, want):
    if got == want:
        print("ok   %s" % name)
    else:
        failures.append(name)
        print("FAIL %s\n  got:  %r\n  want: %r" % (name, got, want))


# RACE framing (verified against the real dongle's replies)
check("race enable CoAP client",
      tb.race(0x9942).hex(), "055a02004299")
check("race GSI GET",
      (tb.race(0x9902, tb.coap_get("GSI"))).hex(),
      "055a0a000299400100" + "01b3475349")
check("coap_get GSI",
      tb.coap_get("GSI").hex(), "4001" + "0001" + "b3475349")
check("race length counts id bytes",
      tb.race(0x0000, b"\x01\x02").hex(), "055a040000000102")

# GSI parsing - sample captured from a live Stealth 700X Gen 3
LIVE = {"OR": "GSI", "KVP": {"200": "1", "210": "0", "220": "My Headset",
                             "230": "1", "240": "90", "250": "0",
                             "260": "86", "270": "0"}}
st = tb.parse_gsi(LIVE)
check("parse linked name", st["name"], "My Headset")
check("parse connected", st["connected"], True)
check("parse battery", st["battery"], 90)
check("parse charging", st["charging"], False)
st_off = tb.parse_gsi({"OR": "GSI", "KVP": {"230": "0", "240": "40"}})
check("parse unlinked", st_off["connected"], False)
check("parse missing battery", tb.parse_gsi({"KVP": {}})["battery"], None)
check("parse absent doc", tb.parse_gsi(None), None)
check("parse battery clamped", tb.parse_gsi({"KVP": {"240": "140"}})["battery"], 100)

if failures:
    print("\n%d failure(s)" % len(failures))
    sys.exit(1)
print("\nall tests passed")
