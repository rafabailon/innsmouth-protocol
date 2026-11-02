#!/usr/bin/env python3
"""Generate the game's original, loopable harbour ambience using only stdlib."""

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22050
DURATION_SECONDS = 8
OUTPUT = Path(__file__).resolve().parents[1] / "assets/audio/innsmouth_ambience.wav"


def main() -> None:
    random.seed(1927)
    phases = [random.uniform(0.0, math.tau) for _ in range(120)]
    samples = bytearray()

    for frame in range(SAMPLE_RATE * DURATION_SECONDS):
        time = frame / SAMPLE_RATE
        wind = sum(
            math.sin(math.tau * harmonic * time / DURATION_SECONDS + phases[harmonic - 1])
            / harmonic**0.82
            for harmonic in range(1, len(phases) + 1)
        )
        swell = 0.72 + 0.28 * math.sin(math.tau * time / DURATION_SECONDS)
        drone = (
            0.26 * math.sin(math.tau * 55.0 * time)
            + 0.17 * math.sin(math.tau * 73.0 * time + 0.4)
            + 0.12 * math.sin(math.tau * 41.0 * time + 1.1)
        )
        value = max(-1.0, min(1.0, (0.18 * wind * swell + drone) * 0.52))
        samples.extend(struct.pack("<h", round(value * 32767)))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(SAMPLE_RATE)
        audio.writeframes(samples)


if __name__ == "__main__":
    main()
