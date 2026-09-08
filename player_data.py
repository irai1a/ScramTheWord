"""Player Data Management Module for Scram The Word.

Uses Kivy's JsonStore to persist player progression, economy, and cosmetic items
locally on the device.
"""

import os
from typing import Any, Dict, List, Optional
from kivy.event import EventDispatcher
# pyrefly: ignore [missing-import]
from kivy.properties import ListProperty, NumericProperty, ObjectProperty
from kivy.storage.jsonstore import JsonStore


class PlayerDataManager(EventDispatcher):
    """Manages player progress, inventory, and statistics locally using Kivy's JsonStore.

    Tracks:
        - coins (int, default: 0)
        - current_stage (int, default: 1)
        - owned_accessories (list of str, default: [])
        - equipped_accessory (str or None, default: None)
    """

    coins = NumericProperty(0)
    current_stage = NumericProperty(1)
    owned_accessories = ListProperty([])
    equipped_accessory = ObjectProperty(None, allownone=True)
    bgm_volume = NumericProperty(0.60)
    sfx_volume = NumericProperty(0.80)

    STORE_KEY = "player_progress"

    def __init__(self, filename: Optional[str] = None, auto_save: bool = True, **kwargs):
        super().__init__(**kwargs)
        if not filename:
            try:
                from kivy.app import App
                app = App.get_running_app()
                if app and hasattr(app, "user_data_dir"):
                    os.makedirs(app.user_data_dir, exist_ok=True)
                    filename = os.path.join(app.user_data_dir, "player_data.json")
                else:
                    filename = "player_data.json"
            except Exception:
                filename = "player_data.json"
        self.filename = filename
        self.auto_save = auto_save
        try:
            self.store = JsonStore(filename)
            self.load()
        except Exception as e:
            print(f"[PlayerDataManager] Warning: Could not initialize JsonStore with {filename}: {e}")
            import tempfile
            fallback = os.path.join(tempfile.gettempdir(), "fallback_player_data.json")
            self.store = JsonStore(fallback)
            self.load()

    # -------------------------------------------------------------------------
    # Read Functions
    # -------------------------------------------------------------------------

    def get_coins(self) -> int:
        """Return the current coin count."""
        return int(self.coins)

    def get_current_stage(self) -> int:
        """Return the current unlocked stage number."""
        return int(self.current_stage)

    def get_owned_accessories(self) -> List[str]:
        """Return a copy of all owned accessory IDs."""
        return list(self.owned_accessories)

    def get_equipped_accessory(self) -> Optional[str]:
        """Return the ID of the currently equipped accessory, or None."""
        return self.equipped_accessory

    def has_accessory(self, accessory_id: str) -> bool:
        """Check if the player owns a specific accessory."""
        return accessory_id in self.owned_accessories

    def get_all_data(self) -> Dict[str, Any]:
        """Return a dictionary snapshot of all player data."""
        return {
            "coins": self.get_coins(),
            "current_stage": self.get_current_stage(),
            "owned_accessories": self.get_owned_accessories(),
            "equipped_accessory": self.get_equipped_accessory(),
            "bgm_volume": self.get_bgm_volume(),
            "sfx_volume": self.get_sfx_volume(),
        }

    def get_bgm_volume(self) -> float:
        """Return BGM volume float (0.0 to 1.0)."""
        return float(self.bgm_volume)

    def get_sfx_volume(self) -> float:
        """Return SFX volume float (0.0 to 1.0)."""
        return float(self.sfx_volume)

    # -------------------------------------------------------------------------
    # Update Functions
    # -------------------------------------------------------------------------

    def set_coins(self, amount: int, persist: bool = True) -> int:
        """Set player coins to an exact non-negative amount."""
        self.coins = max(0, int(amount))
        if persist:
            self.persist()
        return self.get_coins()

    def add_coins(self, amount: int, persist: bool = True) -> int:
        """Add coins to player balance."""
        if amount > 0:
            self.coins += int(amount)
            if persist:
                self.persist()
        return self.get_coins()

    def spend_coins(self, amount: int, persist: bool = True) -> bool:
        """Attempt to spend a given amount of coins.

        Returns True if transaction succeeded, False if insufficient balance.
        """
        amount = int(amount)
        if amount < 0 or self.coins < amount:
            return False
        self.coins -= amount
        if persist:
            self.persist()
        return True

    def set_current_stage(self, stage: int, persist: bool = True) -> int:
        """Set current stage number (minimum 1)."""
        self.current_stage = max(1, int(stage))
        if persist:
            self.persist()
        return self.get_current_stage()

    def advance_stage(self, persist: bool = True) -> int:
        """Increment current stage by 1."""
        self.current_stage += 1
        if persist:
            self.persist()
        return self.get_current_stage()

    def add_accessory(self, accessory_id: str, persist: bool = True) -> bool:
        """Add an accessory to the owned accessories list.

        Returns True if newly added, False if already owned or invalid ID.
        """
        if not accessory_id or not isinstance(accessory_id, str):
            return False
        if accessory_id not in self.owned_accessories:
            self.owned_accessories.append(accessory_id)
            if persist:
                self.persist()
            return True
        return False

    def equip_accessory(self, accessory_id: Optional[str], persist: bool = True) -> bool:
        """Equip an accessory.

        Must be in owned_accessories, or None to unequip.
        Returns True if successful, False if accessory is not owned.
        """
        if accessory_id is None:
            self.equipped_accessory = None
            if persist:
                self.persist()
            return True

        if isinstance(accessory_id, str) and accessory_id in self.owned_accessories:
            self.equipped_accessory = accessory_id
            if persist:
                self.persist()
            return True
        return False

    def unequip_accessory(self, persist: bool = True) -> bool:
        """Unequip currently equipped accessory."""
        return self.equip_accessory(None, persist=persist)

    def set_bgm_volume(self, amount: float, persist: bool = True) -> float:
        """Set BGM volume (0.0 to 1.0)."""
        self.bgm_volume = max(0.0, min(1.0, float(amount)))
        if persist:
            self.persist()
        return self.get_bgm_volume()

    def set_sfx_volume(self, amount: float, persist: bool = True) -> float:
        """Set SFX volume (0.0 to 1.0)."""
        self.sfx_volume = max(0.0, min(1.0, float(amount)))
        if persist:
            self.persist()
        return self.get_sfx_volume()

    def reset_to_defaults(self, persist: bool = True) -> Dict[str, Any]:
        """Reset all player data back to initial defaults."""
        self.coins = 0
        self.current_stage = 1
        self.owned_accessories = []
        self.equipped_accessory = None
        self.bgm_volume = 0.60
        self.sfx_volume = 0.80
        if persist:
            self.persist()
        return self.get_all_data()

    # -------------------------------------------------------------------------
    # Persistence Functions (JsonStore)
    # -------------------------------------------------------------------------

    def persist(self) -> None:
        """Persist current in-memory values to Kivy's JsonStore."""
        try:
            self.store.put(
                self.STORE_KEY,
                coins=int(self.coins),
                current_stage=int(self.current_stage),
                owned_accessories=list(self.owned_accessories),
                equipped_accessory=self.equipped_accessory,
                bgm_volume=float(self.bgm_volume),
                sfx_volume=float(self.sfx_volume),
            )
        except Exception as e:
            print(f"[PlayerDataManager] Warning: Could not persist player data ({e})")

    def save(self) -> None:
        """Alias for persist()."""
        self.persist()

    def load(self) -> Dict[str, Any]:
        """Load data from JsonStore into in-memory attributes.

        If no existing store entry is found, initializes store with default values.
        """
        try:
            if self.store.exists(self.STORE_KEY):
                data = self.store.get(self.STORE_KEY)
                self.coins = int(data.get("coins", 0))
                self.current_stage = int(data.get("current_stage", 1))
                self.owned_accessories = list(data.get("owned_accessories", []))
                self.equipped_accessory = data.get("equipped_accessory", None)
                self.bgm_volume = float(data.get("bgm_volume", 0.60))
                self.sfx_volume = float(data.get("sfx_volume", 0.80))
            else:
                # First launch: persist initial default state
                self.persist()
        except Exception as e:
            print(f"[PlayerDataManager] Warning: Could not load player data ({e})")

        # Synchronize loaded volumes with AudioManager
        try:
            from audio_manager import AudioManager
            am = AudioManager.get_instance()
            am.set_bgm_volume(self.bgm_volume)
            am.set_sfx_volume(self.sfx_volume)
        except Exception:
            pass

        return self.get_all_data()

    def __repr__(self) -> str:
        return (
            f"<PlayerDataManager coins={self.coins} stage={self.current_stage} "
            f"owned={len(self.owned_accessories)} equipped={self.equipped_accessory}>"
        )
