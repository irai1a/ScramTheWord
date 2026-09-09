"""Audio Manager for Whack-A-Word-Ham.

Manages background music (BGM) tracks and sound effects (SFX):
- Background music as soon as the player starts the game (Front Page and Map Page share 'main')
- Background music when entering Stage Mode ('stage')
- Background music for Hamster Wardrobe ('wardrobe')
- Tactile wooden button click SFX on all button interactions
- Additional puzzle action SFX (tile tap, hint reveal, solve chime, wrong attempt)
"""

import os
from typing import Dict, Optional
from kivy.core.audio import Sound, SoundLoader


class AudioManager:
    """Centralized sound and music controller for Whack-A-Word-Ham."""

    _instance: Optional["AudioManager"] = None

    BGM_FILES = {
        "main": os.path.join("assets", "audio", "bgm_main.wav"),
        "stage": os.path.join("assets", "audio", "bgm_stage.wav"),
        "wardrobe": os.path.join("assets", "audio", "bgm_wardrobe.wav"),
    }

    SFX_FILES = {
        "click": os.path.join("assets", "audio", "sfx_click.wav"),
        "tile": os.path.join("assets", "audio", "sfx_tile.wav"),
        "success": os.path.join("assets", "audio", "sfx_success.wav"),
        "wrong": os.path.join("assets", "audio", "sfx_wrong.wav"),
        "hint": os.path.join("assets", "audio", "sfx_hint.wav"),
    }

    def __init__(self):
        self._current_bgm_track: Optional[str] = None
        self._current_bgm_sound: Optional[Sound] = None
        self._loaded_sfx: Dict[str, Sound] = {}
        self._bgm_volume: float = 0.55
        self._sfx_volume: float = 0.80
        self._is_muted: bool = False
        self._preload_sounds()

    @classmethod
    def get_instance(cls) -> "AudioManager":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _preload_sounds(self):
        """Preload SFX to eliminate latency on button taps, safely ignoring errors."""
        base_dir = os.path.dirname(os.path.abspath(__file__))
        for key, rel_path in self.SFX_FILES.items():
            full_path = os.path.join(base_dir, rel_path)
            if os.path.exists(full_path):
                try:
                    snd = SoundLoader.load(full_path)
                    if snd:
                        snd.volume = self._sfx_volume
                        self._loaded_sfx[key] = snd
                except Exception as e:
                    print(f"[AudioManager] Notice: Could not preload SFX '{key}': {e}")

    # -------------------------------------------------------------------------
    # Background Music (BGM)
    # -------------------------------------------------------------------------

    def play_bgm(self, track_name: str, force_restart: bool = False):
        """Play requested background music track ('main', 'stage', 'wardrobe').

        If the requested track is already currently playing (e.g. moving between
        Front Page and Map Page), it continues playing seamlessly without interruption.
        """
        if self._is_muted:
            return

        track_name = track_name.lower().strip()
        if track_name not in self.BGM_FILES:
            print(f"[AudioManager] Warning: Unknown BGM track '{track_name}'")
            return

        # If already playing this track and not forcing a restart, keep playing uninterrupted!
        if self._current_bgm_track == track_name and self._current_bgm_sound:
            try:
                if getattr(self._current_bgm_sound, "state", None) == "play":
                    return
            except Exception:
                pass

        # Stop previous track safely
        self.stop_bgm()

        base_dir = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(base_dir, self.BGM_FILES[track_name])

        if not os.path.exists(file_path):
            print(f"[AudioManager] Warning: BGM file not found: {file_path}")
            return

        try:
            sound = SoundLoader.load(file_path)
            if sound:
                sound.loop = True
                sound.volume = self._bgm_volume
                sound.play()
                self._current_bgm_sound = sound
                self._current_bgm_track = track_name
        except Exception as err:
            print(f"[AudioManager] Notice: Audio not available or failed to play BGM '{track_name}': {err}")

    def stop_bgm(self):
        """Stop currently active background music safely without native buffer unloads."""
        if self._current_bgm_sound:
            try:
                self._current_bgm_sound.stop()
            except Exception:
                pass
            self._current_bgm_sound = None
        self._current_bgm_track = None

    def pause_bgm(self):
        """Pause active background music."""
        if self._current_bgm_sound:
            try:
                if getattr(self._current_bgm_sound, "state", None) == "play":
                    self._current_bgm_sound.stop()
            except Exception:
                pass

    def resume_bgm(self):
        """Resume paused background music."""
        if self._current_bgm_sound and not self._is_muted:
            try:
                self._current_bgm_sound.play()
            except Exception:
                pass

    # -------------------------------------------------------------------------
    # Sound Effects (SFX)
    # -------------------------------------------------------------------------

    def play_sfx(self, sfx_name: str):
        """Play a one-shot sound effect by key name."""
        if self._is_muted:
            return

        sfx_name = sfx_name.lower().strip()
        sound = self._loaded_sfx.get(sfx_name)
        if not sound:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            rel_path = self.SFX_FILES.get(sfx_name)
            if rel_path:
                full_path = os.path.join(base_dir, rel_path)
                if os.path.exists(full_path):
                    try:
                        sound = SoundLoader.load(full_path)
                        if sound:
                            self._loaded_sfx[sfx_name] = sound
                    except Exception:
                        pass

        if sound:
            try:
                sound.volume = self._sfx_volume
                sound.play()
            except Exception as e:
                print(f"[AudioManager] Notice: Could not play SFX '{sfx_name}': {e}")

    def play_click(self):
        """Convenience method to play button click sound effect."""
        self.play_sfx("click")

    def play_tile(self):
        """Convenience method to play letter tile tap sound effect."""
        self.play_sfx("tile")

    def play_success(self):
        """Convenience method to play solve celebration chime."""
        self.play_sfx("success")

    def play_wrong(self):
        """Convenience method to play gentle wrong answer bonk."""
        self.play_sfx("wrong")

    def play_hint(self):
        """Convenience method to play hint unlock chime."""
        self.play_sfx("hint")

    # -------------------------------------------------------------------------
    # Volume Controls
    # -------------------------------------------------------------------------

    def get_bgm_volume(self) -> float:
        """Return current BGM volume float (0.0 to 1.0)."""
        return self._bgm_volume

    def set_bgm_volume(self, volume: float):
        """Set BGM volume (0.0 to 1.0) and immediately update playing track."""
        self._bgm_volume = max(0.0, min(1.0, float(volume)))
        if self._current_bgm_sound:
            try:
                self._current_bgm_sound.volume = self._bgm_volume
            except Exception:
                pass

    def get_sfx_volume(self) -> float:
        """Return current SFX volume float (0.0 to 1.0)."""
        return self._sfx_volume

    def set_sfx_volume(self, volume: float):
        """Set SFX volume (0.0 to 1.0) and update preloaded sound effects."""
        self._sfx_volume = max(0.0, min(1.0, float(volume)))
        for snd in self._loaded_sfx.values():
            try:
                snd.volume = self._sfx_volume
            except Exception:
                pass


# Global shortcut functions for clean access across all modules
def play_bgm(track: str):
    try:
        AudioManager.get_instance().play_bgm(track)
    except Exception as e:
        print(f"[AudioManager] play_bgm notice: {e}")


def stop_bgm():
    try:
        AudioManager.get_instance().stop_bgm()
    except Exception as e:
        print(f"[AudioManager] stop_bgm notice: {e}")


def play_click():
    try:
        AudioManager.get_instance().play_click()
    except Exception as e:
        print(f"[AudioManager] play_click notice: {e}")


def play_sfx(name: str):
    try:
        AudioManager.get_instance().play_sfx(name)
    except Exception as e:
        print(f"[AudioManager] play_sfx notice: {e}")


def set_bgm_volume(vol: float):
    try:
        AudioManager.get_instance().set_bgm_volume(vol)
    except Exception:
        pass


def get_bgm_volume() -> float:
    try:
        return AudioManager.get_instance().get_bgm_volume()
    except Exception:
        return 0.6


def set_sfx_volume(vol: float):
    try:
        AudioManager.get_instance().set_sfx_volume(vol)
    except Exception:
        pass


def get_sfx_volume() -> float:
    try:
        return AudioManager.get_instance().get_sfx_volume()
    except Exception:
        return 0.8
