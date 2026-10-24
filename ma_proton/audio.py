"""
audio.py - macOS CoreAudio integration and low-latency audio driver configuration.
"""

from typing import Dict

class AudioManager:
    """Configures low-latency audio bridging to Darwin CoreAudio."""

    def __init__(self, driver: str = "coreaudio"):
        self.driver = driver

    def get_env_variables(self) -> Dict[str, str]:
        env = {
            "WINEAUDIO": self.driver,
            # Audio latency buffer settings for macOS CoreAudio
            "COREAUDIO_BUFFER_SIZE": "512",
            "PULSE_LATENCY_MSEC": "20"
        }
        return env
