# tb-heal

One command for the whole Turtle Beach Stealth 700 Gen 3 audio path:
real link + battery status read straight from the USB transmitter, plus
automatic repair of everything on the PC side that can silently break.

```
tb-heal
My Headset: linked. battery 90%.
  sink: alsa_output.usb-Turtle_Beach...analog-stereo [default=True vol=41% muted=False]
```

## Why this exists

The Stealth 700 Gen 3 is three devices, and the PC only ever sees the first:

```
PC ──USB──> dongle ──2.4 GHz──> headset ──> your ears
     always connected      only exists when the headset is powered ON
```

- The dongle is a radio station. It accepts audio whether or not anyone is
  listening, so the PC always looks perfectly healthy in your audio settings.
- Auto-connect runs on the headset, only while it is powered on. Nothing can
  ever wake the headset from the PC.
- The headset's USB-C port is a charger (and firmware port). **It never
  carries audio, on any OS.** Plugging it in to "listen wired" silently does
  nothing.

Result: "no audio" almost always means the headset is not linked to the
dongle, and no stock OS tool can tell you that. `tb-heal` reads the headset's
own status from the transmitter's chip (the same read-only exchange the
official Swarm II app performs) and prints an exact fix-it ladder when the
problem is on your head.

## Platform support

| Platform | Status query (link + battery) | PC-side self-heal | Verified |
|---|---|---|---|
| Linux | yes | yes (PipeWire: default sink, mute, volume floor) | yes - kernel 7.2, PipeWire 1.6, CachyOS/Arch |
| Windows 10/11 | yes (hidapi.dll or `pip install hidapi`) | n/a (set the dongle as default device in Settings) | not by this repo - chip-side protocol verified on Windows upstream |
| macOS | yes (`brew install hidapi` or `pip install hidapi`) | n/a | no (no hardware available) |

The chip-side protocol (Airoha RACE + CoAP) is plain USB HID and fully
platform-agnostic; the differences are only which hidapi build you load and
which audio stack the heal layer drives. On Linux the **libusb backend is
required**: on kernel 7.x the hidraw path is broken for this dongle (its HID
interface has no interrupt-OUT endpoint - hidraw writes are silently dropped
and GET_REPORT pulls return a zeroed cache).

Supported hardware: Turtle Beach Stealth 700 Gen 3 transmitters
(`10f5:2251`, siblings `2250`/`2253`). Other Gen 3 models (Stealth 500,
Stealth 600 Gen 3, Atlas Air) speak the same firmware family - try it and
report back.

## Install

Linux (recommended, includes the udev rule so no sudo is needed later):

```sh
git clone https://github.com/richard523/tb-heal.git
cd tb-heal
sudo ./install.sh          # /usr/local/bin + udev rule
# or: ./install.sh --user  # ~/.local/bin, no udev rule
```

macOS:

```sh
brew install hidapi
sudo ./install.sh          # or ./install.sh --user
```

Windows (PowerShell):

```powershell
pip install hidapi
.\install.ps1
```

## Usage

| Command | Effect |
|---|---|
| `tb-heal` | one shot: heal the PC side, report link/battery; prints the fix-it ladder if unlinked. Exit 0 linked / 1 human action needed / 2 no transmitter (or hidapi missing) |
| `tb-heal --wait [SECS]` | poll every 3s, desktop notification + exit 0 the moment the link comes up |
| `tb-heal --watch` | run forever; re-heals each poll, notifies on every link transition |
| `tb-heal --json` | machine-readable one shot |
| `tb-heal --no-heal` | report only, change nothing |
| `tb-heal --diagnose` | raw HID exchange (debug) |

What it self-heals (Linux): default sink forced back to the dongle, sink
unmuted, zero-ish volume raised to 40%. What it detects and instructs on:
headset off / out of range, headset sitting on its charge cable, wedged
transmitter, missing transmitter.

The fix-it ladder it prints (all steps from Turtle Beach's official docs):
power the headset on -> dongle LED solid green -> hold CROSSPLAY+MODE 10s
(hard reset, auto re-pair) -> 3x-insert transmitter pairing dance + 5-8s
power hold.

Concurrent invocations are safe: every USB exchange takes an advisory lock
(`/tmp/tb-heal.lock`), so a tray daemon polling while you run tb-heal
manually just waits its turn instead of colliding on the device.

## Protocol (for the curious)

- The transmitter is an Airoha chip speaking the **RACE** protocol on its
  HID vendor collection (usage page `0xFF13`).
- Transport: HID output report `0x06` = `06 <len16> <race>`, replies as
  input report `0x07` with the same prefix. RACE command:
  `05 5A <len16> <id16> <payload>`; response starts `05 5B`.
- Exchange: enable the on-chip CoAP client (RACE `0x9942`), then CoAP
  `GET /GSI` tunnelled in RACE `0x9902`. Each input-report read pops the
  next chunk of the reply, so the reader drains stale reports first and
  accumulates chunks until the JSON closes.
- GSI JSON keys: `220` name, `230` connected, `240` battery %, `250` charging.
  With the headset off, the reply still carries last-known battery with
  `230=0`.
- **Read-only**: the only thing written is the enable command for the chip's
  own CoAP client - exactly what Swarm II does. No settings, no firmware.

## Credits

- Protocol reverse-engineering: [PaulRichez/halobattery-stealth700](https://github.com/PaulRichez/halobattery-stealth700)
  and [HaloBattery PR #211](https://github.com/HeyOkay/HaloBattery/pull/211)
  (from Swarm II 1.0.0.57). This tool's transport replicates that exchange
  against the same PID and was verified live on Linux.
- Pairing/hard-reset procedures: Turtle Beach support articles for the
  Stealth 700 Gen 3.

## License

MIT - see [LICENSE](LICENSE).
