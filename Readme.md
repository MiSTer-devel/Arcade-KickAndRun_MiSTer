# Taito Kick And Run

This is a port of the classic Taito arcade game Kick And Run for the MiSTer FPGA platform by Pierco. The core is currently not compatible with Kiki Kaikai due to the lack of an MCU dump. However, I am actively working on it and I started to recreate a custom ROM in assembly. I hope to make the core compatible soon.

## Original Hardware

I tried to reproduce the PCB but all the PAL chips have been replaced with simple logic. In order to simplify the rendering logic, I added a DMA that is not present in the [original design](./doc/KickAndRun.pdf).

## Known bugs

- Sound may not always be active as intended in attract mode when the "demo sounds" switch is enabled. Additionally, during gameplay, certain sounds are skipped, and lastly, some level adjustments are needed.
- It's likely a stupid error, but the aspect ratio does not work in OSD.

## Thank you!

I would like to thank all my contributors on Patreon and everyone who has provided assistance and support to me.

We need more sport games on MiSTerFPGA!
