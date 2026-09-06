"""Stage Mode gameplay logic for Scram The Word.

Handles:
- Loading words from words.json
- Selecting words based on current_stage (shorter for lower stages, longer for higher stages)
- Scrambling letters and rendering clickable KivyMD letter cards
- Letter assembly area with interactive add/remove mechanics
- Submit validation: awards 10 coins, increments current_stage, persists via JsonStore,
  and advances to the next stage with a success banner.
"""

import json
import os
import random
from typing import Any, Dict, List, Optional, Tuple

from kivy.animation import Animation
from kivy.clock import Clock
from kivy.factory import Factory
from kivy.metrics import dp
from kivy.properties import (
    BooleanProperty,
    ColorProperty,
    ListProperty,
    NumericProperty,
    StringProperty,
)
from kivy.uix.behaviors import ButtonBehavior
from kivy.uix.image import Image
from kivymd.app import MDApp
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.card import MDCard
from kivymd.uix.label import MDLabel
from kivymd.uix.relativelayout import MDRelativeLayout
from kivymd.uix.screen import MDScreen

from avatar_shop import ACCESSORIES
from word_generator import generate_stage, scramble_letters as gen_scramble_letters
from audio_manager import play_bgm, play_click, play_sfx


# Positive hamster companion cheer lines (clean punctuation, no missing glyphs)
HAMSTER_GREETINGS = [
    "You've got this, pal! Let's crack this word!",
    "Sniffing out the clues! Squeak squeak!",
    "Believe in yourself! Every letter counts!",
    "Take your time, buddy. I know you can solve it!",
    "Together we're unstoppable! Squeak!",
]

WRONG_ATTEMPT_COMMENTS = [
    "Don't give up! Look, there's a new hint for you!",
    "So close! Tap the Hint button for a fresh clue!",
    "Paws up! A helpful hint just unlocked above!",
    "Shake it off! Check the Hint button to guide you!",
    "Mistakes make us smarter! Tap the Hint button!",
]

HINT_UNLOCKED_COMMENTS = [
    "Aha! Here is a fresh clue to guide your way!",
    "Look closely at this clue, my friend!",
    "Ooh, that's a great clue! Can you spot the word now?",
    "Every hint brings us closer to victory! Squeak!",
]

ALL_HINTS_COMMENTS = [
    "You've unlocked all 5 hints! You can do this!",
    "All clues revealed! Take a breath and arrange the letters!",
]

SOLVE_COMMENTS = [
    "WOOHOO! Brilliant wordplay! Squeak!",
    "You did it! That was amazing! High-paw!",
    "Pure genius! Look at those shiny coins!",
]


class LetterTile(ButtonBehavior, MDRelativeLayout):
    """Clickable carved wooden letter tile widget with authentic wood-grain texture and embossed letter."""

    def __init__(
        self,
        letter: str,
        tile_id: int,
        on_click_callback,
        is_assembled: bool = False,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.letter = letter.upper()
        self.tile_id = tile_id
        self.on_click_callback = on_click_callback
        self.is_assembled = is_assembled

        self.size_hint = (None, None)
        self.size = (dp(48), dp(52))
        self.pos_hint = {"center_y": 0.5}

        # Tap event binding
        self.bind(on_release=lambda instance: self.on_click_callback(self))

        # Wooden tile texture
        self.normal_bg = "assets/wood_tile_assembled.png" if is_assembled else "assets/wood_tile_normal.png"
        self.bg_img = Image(
            source=self.normal_bg,
            size_hint=(1, 1),
            fit_mode="fill",
            pos_hint={"center_x": 0.5, "center_y": 0.5},
        )
        self.add_widget(self.bg_img)

        # Deep carved burnt-wood letter typography
        self.label = MDLabel(
            text=self.letter,
            halign="center",
            valign="center",
            bold=True,
            font_style="Headline",
            role="small",
            theme_text_color="Custom",
            text_color=[0.24, 0.12, 0.05, 1.0],
            adaptive_size=False,
            size_hint=(1, 1),
            pos_hint={"center_x": 0.5, "center_y": 0.52},
        )
        self.add_widget(self.label)

    def on_touch_down(self, touch):
        if not self.collide_point(*touch.pos):
            return False
        if self.disabled:
            return True
        if touch.is_mouse_scrolling or self in touch.ud:
            return False
        touch.grab(self)
        touch.ud[self] = True
        self.last_touch = touch
        self.state = "down"
        play_sfx("tile")
        self.dispatch("on_press")
        return True

    def on_touch_up(self, touch):
        if touch.grab_current is not self:
            return False
        touch.ungrab(self)
        self.last_touch = touch
        self.state = "normal"
        if self.collide_point(*touch.pos):
            self.dispatch("on_release")
        return True

    def on_state(self, instance, value):
        """Visual tactile feedback on touch down/up."""
        if hasattr(self, "bg_img"):
            if value == "down" and not self.disabled:
                self.bg_img.source = "assets/wood_tile_pressed.png"
            else:
                self.bg_img.source = self.normal_bg


class WoodHintButton(ButtonBehavior, MDRelativeLayout):
    """Clickable wooden tag-style Hint button with reactive red notification badge."""

    button_text = StringProperty("HINT (1/5)")
    badge_text = StringProperty("1")
    has_badge = BooleanProperty(False)
    is_pressed = BooleanProperty(False)

    def on_touch_down(self, touch):
        if not self.collide_point(*touch.pos):
            return False
        # The hint button can ONLY be clicked when it has the red notification mark!
        if not self.has_badge or self.disabled or getattr(self, "is_disabled", False):
            return True
        if touch.is_mouse_scrolling or self in touch.ud:
            return False
        touch.grab(self)
        touch.ud[self] = True
        self.last_touch = touch
        self.state = "down"
        self.is_pressed = True
        play_click()
        self.dispatch("on_press")
        return True

    def on_touch_up(self, touch):
        if touch.grab_current is not self:
            return False
        touch.ungrab(self)
        self.last_touch = touch
        self.state = "normal"
        self.is_pressed = False
        if self.collide_point(*touch.pos):
            self.dispatch("on_release")
        return True

    def on_state(self, instance, value):
        self.is_pressed = (value == "down")


Factory.register("LetterTile", cls=LetterTile)
Factory.register("WoodHintButton", cls=WoodHintButton)


class StageModeScreen(MDScreen):
    """Stage Mode screen managing word scramble gameplay, clues, animations, progression, and hamster companion."""

    target_word = StringProperty("")
    word_description = StringProperty("")
    scrambled_word = StringProperty("")
    assembled_word = StringProperty("")
    current_stage_display = NumericProperty(1)
    word_length_display = NumericProperty(0)
    attempts_count = NumericProperty(1)
    potential_reward = NumericProperty(10)
    coins_display = NumericProperty(0)

    # Banner properties
    banner_text = StringProperty("Read the clue and unscramble the letters below.")
    banner_bg_color = ColorProperty([0.22, 0.15, 0.09, 0.92])
    banner_text_color = ColorProperty([0.96, 0.92, 0.84, 1.0])
    is_correct_state = BooleanProperty(False)

    # Hamster Cheerleader Companion properties
    hamster_comment = StringProperty("You've got this, pal! Let's crack this word!")
    hamster_frame1_opacity = NumericProperty(1.0)
    hamster_frame2_opacity = NumericProperty(0.0)
    equipped_overlay_source = StringProperty("assets/empty.png")
    _breathing_clock_event = None

    # Hint System properties (up to 5 hints per stage)
    hints_list = ListProperty([])
    unlocked_hints_count = NumericProperty(1)
    current_hint_index = NumericProperty(0)
    has_unread_hint = BooleanProperty(False)
    active_hint_display = StringProperty("")
    hint_button_label = StringProperty("HINT (1/5)")

    # Target stage requested by MapScreen
    target_stage_to_load = NumericProperty(0)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.words_db = self.load_words_db()
        self.scrambled_tiles: List[Tuple[int, str]] = []
        self.assembled_tiles: List[Tuple[int, str]] = []
        self.tile_widgets: Dict[int, LetterTile] = {}
        self.assembled_tile_widgets: List[LetterTile] = []

    def load_words_db(self) -> Dict[str, List[Any]]:
        """Load English word lists and subtle clues grouped by length from local words.json file."""
        json_path = os.path.join(os.path.dirname(__file__), "words.json")
        if os.path.exists(json_path):
            try:
                with open(json_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                print(f"[StageMode] Warning: Could not parse words.json ({e}). Using fallback words.")

        # Fallback word dictionary if file is missing or corrupted
        return {
            "3": [
                {
                    "word": "CAT",
                    "description": "A curious hunter that purrs softly in warm sunlight.",
                    "hints": [
                        "A curious hunter that purrs softly in warm sunlight.",
                        "A beloved household pet known for agile jumps and climbing high perches.",
                        "Equipped with retractable claws, sharp whiskers, and keen night vision.",
                        "Chases laser dots and playful balls of yarn with stealthy pounces.",
                        "A 3-letter feline that rhymes with 'BAT' and 'HAT'.",
                    ],
                },
            ],
        }

    def on_enter(self, *args):
        """Called automatically whenever the user navigates into StageModeScreen."""
        super().on_enter(*args)
        play_bgm("stage")
        app = MDApp.get_running_app()
        stage = 1
        if hasattr(app, "player_data") and app.player_data is not None:
            app.player_data.load()
            stage = app.player_data.get_current_stage()
            self.coins_display = app.player_data.get_coins()
            app.player_data.bind(coins=self._on_coins_changed)

        if self.target_stage_to_load > 0:
            stage = int(self.target_stage_to_load)
            self.target_stage_to_load = 0

        self.update_hamster_accessory()
        self.load_stage(stage)
        self.start_hamster_idle()

    def on_leave(self, *args):
        """Called automatically whenever the user navigates away from StageModeScreen."""
        super().on_leave(*args)
        self.stop_hamster_idle()

    def _on_coins_changed(self, instance, value):
        self.coins_display = int(value)

    def update_hamster_accessory(self):
        """Sync hamster cheerleader companion accessory from JsonStore."""
        app = MDApp.get_running_app()
        equipped_id = None
        if hasattr(app, "player_data") and app.player_data is not None:
            equipped_id = app.player_data.get_equipped_accessory()

        self.equipped_overlay_source = "assets/empty.png"
        if equipped_id:
            for item in ACCESSORIES:
                if item.get("id") == equipped_id:
                    self.equipped_overlay_source = item.get("overlay", "assets/empty.png")
                    break

    def cut_to_frame1(self, dt=0):
        """Clean instant cut to Frame 1 (alert / inhale). Zero opacity crossfade."""
        self.hamster_frame1_opacity = 1.0
        self.hamster_frame2_opacity = 0.0

    def cut_to_frame2(self, dt=0):
        """Clean instant cut to Frame 2 (happy squinting smile / exhale). Zero opacity crossfade."""
        self.hamster_frame1_opacity = 0.0
        self.hamster_frame2_opacity = 1.0

    def start_hamster_idle(self):
        """Start clean, discrete breathing idle animation without any ghosting or floating."""
        container = self.ids.get("hamster_stage_idle_container")
        if not container:
            return

        Animation.stop_all(container)
        self.stop_hamster_idle()
        container.pos_hint = {"center_x": 0.5, "center_y": 0.5}
        container.size_hint = (1.0, 1.0)
        self.cut_to_frame1()

        def switch_to_exhale(dt):
            self.cut_to_frame2()
            self._breathing_clock_event = Clock.schedule_once(switch_to_inhale, 1.2)

        def switch_to_inhale(dt):
            self.cut_to_frame1()
            self._breathing_clock_event = Clock.schedule_once(switch_to_exhale, 1.8)

        self._breathing_clock_event = Clock.schedule_once(switch_to_exhale, 1.8)

    def stop_hamster_idle(self):
        """Cleanly cancel the breathing animation and reset to resting frame."""
        if self._breathing_clock_event:
            self._breathing_clock_event.cancel()
            self._breathing_clock_event = None
        container = self.ids.get("hamster_stage_idle_container")
        if container:
            Animation.stop_all(container)
            container.pos_hint = {"center_x": 0.5, "center_y": 0.5}
            container.size_hint = (1.0, 1.0)
        self.hamster_frame1_opacity = 1.0
        self.hamster_frame2_opacity = 0.0

    def play_hamster_hop(self):
        """Trigger an energetic celebratory bounce whenever the player solves the stage."""
        container = self.ids.get("hamster_stage_idle_container")
        if not container:
            return
        self.stop_hamster_idle()

        # Happy smiling face during victory hop
        self.cut_to_frame2()

        hop = (
            Animation(
                pos_hint={"center_x": 0.5, "center_y": 0.44},
                size_hint=(1.08, 0.90),
                duration=0.10,
                t="out_quad",
            )
            + Animation(
                pos_hint={"center_x": 0.5, "center_y": 0.62},
                size_hint=(0.95, 1.08),
                duration=0.18,
                t="out_back",
            )
            + Animation(
                pos_hint={"center_x": 0.5, "center_y": 0.46},
                size_hint=(1.06, 0.94),
                duration=0.14,
                t="in_quad",
            )
            + Animation(
                pos_hint={"center_x": 0.5, "center_y": 0.50},
                size_hint=(1.0, 1.0),
                duration=0.10,
                t="out_sine",
            )
        )
        hop.bind(on_complete=lambda *args: self.start_hamster_idle())
        hop.start(container)

    def pulse_clue_box(self):
        """Subtle highlight pulse on the Clue box when a clue is unlocked or cycled."""
        clue_box = self.ids.get("clue_timber_box")
        if clue_box:
            orig_color = [0.14, 0.10, 0.06, 0.88]
            glow_color = [0.36, 0.24, 0.10, 0.95]
            anim = (
                Animation(md_bg_color=glow_color, duration=0.15, t="out_quad")
                + Animation(md_bg_color=orig_color, duration=0.30, t="in_quad")
            )
            anim.start(clue_box)

    def show_previous_hint(self):
        """Navigate to and display the previous unlocked hint."""
        play_click()
        if self.current_hint_index > 0:
            self.current_hint_index -= 1
            if 0 <= self.current_hint_index < len(self.hints_list):
                self.active_hint_display = self.hints_list[self.current_hint_index]
            self.pulse_clue_box()

    def show_next_hint(self):
        """Navigate to and display the next unlocked hint (only unlocked hints can be viewed)."""
        play_click()
        if self.current_hint_index < (self.unlocked_hints_count - 1):
            self.current_hint_index += 1
            if 0 <= self.current_hint_index < len(self.hints_list):
                self.active_hint_display = self.hints_list[self.current_hint_index]
            self.pulse_clue_box()

    def on_hint_button_click(self):
        """Handle tap on the Wood Hint Button.

        Can ONLY be clicked when the red notification mark is active (i.e. after player submits a wrong word).
        Dismisses the red notification mark immediately and reveals the next progressive hint.
        """
        # Strictly require active red notification mark to be clickable
        if not self.has_unread_hint or not self.hints_list:
            return

        max_available = min(5, len(self.hints_list))

        # Dismiss the red notification badge immediately
        self.has_unread_hint = False

        if self.unlocked_hints_count < max_available:
            # Unlock and reveal the next progressive hint!
            play_sfx("hint")
            self.unlocked_hints_count += 1
            self.current_hint_index = int(self.unlocked_hints_count - 1)
            self.active_hint_display = self.hints_list[self.current_hint_index]
            self.hamster_comment = random.choice(HINT_UNLOCKED_COMMENTS)
        else:
            # All 5 hints already unlocked: show the current hint
            play_click()
            self.active_hint_display = self.hints_list[self.current_hint_index]
            self.hamster_comment = random.choice(ALL_HINTS_COMMENTS)

        self.hint_button_label = f"HINT ({self.unlocked_hints_count}/5)"
        self.pulse_clue_box()

    def calculate_coin_reward(self, attempts: int, stage: Optional[int] = None) -> int:
        """Calculate coins to award based on stage difficulty and number of attempts."""
        st = stage if stage is not None else getattr(self, "current_stage_display", 1)
        base = 10 + (max(1, int(st)) // 5)
        if attempts <= 1:
            return base
        elif attempts == 2:
            return max(5, int(base * 0.7))
        else:
            return max(3, int(base * 0.5))

    def get_word_for_stage(self, stage: int) -> Tuple[str, str, List[str]]:
        """Select a word, subtle description, and 5 progressive hints procedurally using generate_stage."""
        stage_data = generate_stage(stage)
        return (
            stage_data["original_word"],
            stage_data.get("description", ""),
            stage_data.get("hints", []),
        )

    def scramble_letters(self, word: str) -> List[str]:
        """Scramble word letters ensuring scrambled sequence != target word."""
        return gen_scramble_letters(word)

    def load_stage(self, stage: int):
        """Load and initialize a new stage with refreshed hints and hamster cheerleader greeting."""
        self.is_correct_state = False
        self.current_stage_display = max(1, int(stage))
        self.attempts_count = 1
        self.potential_reward = self.calculate_coin_reward(self.attempts_count, self.current_stage_display)

        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            self.coins_display = app.player_data.get_coins()

        stage_data = generate_stage(self.current_stage_display)
        self.target_word = stage_data["original_word"]
        self.word_description = stage_data.get("description", "")
        self.hints_list = stage_data.get("hints", [])
        self.unlocked_hints_count = 1
        self.current_hint_index = 0
        self.has_unread_hint = False
        self.active_hint_display = self.hints_list[0] if self.hints_list else ""
        self.hint_button_label = "HINT (1/5)"
        self.hamster_comment = random.choice(HAMSTER_GREETINGS)

        self.word_length_display = len(self.target_word)

        # Scrambled letters from procedural generator
        scrambled_chars = stage_data["scrambled_letters"]
        self.scrambled_word = "".join(scrambled_chars)
        self.scrambled_tiles = [(i, char) for i, char in enumerate(scrambled_chars)]

        # Reset assembly state
        self.assembled_tiles.clear()
        self.assembled_tile_widgets.clear()
        self.assembled_word = ""

        # Re-render widgets
        self.render_scrambled_tiles()
        self.render_assembly_tiles()

        # Re-enable submit/clear buttons and ensure float badge is disabled
        if hasattr(self.ids, "btn_submit"):
            self.ids.btn_submit.disabled = False
        if hasattr(self.ids, "btn_clear"):
            self.ids.btn_clear.disabled = False
        if hasattr(self.ids, "reward_float_badge"):
            self.ids.reward_float_badge.disabled = True
            self.ids.reward_float_badge.opacity = 0.0

        self.set_banner_neutral()

    def render_scrambled_tiles(self):
        """Populate the scrambled letters pool with interactive LetterTile cards."""
        if not hasattr(self.ids, "scrambled_box"):
            return

        box = self.ids.scrambled_box
        box.clear_widgets()
        self.tile_widgets.clear()

        length = len(self.scrambled_tiles)
        # Responsive tile sizing
        tile_w = dp(40) if length >= 8 else (dp(46) if length >= 6 else dp(52))
        tile_h = dp(46) if length >= 8 else (dp(50) if length >= 6 else dp(56))

        # Split across two rows if length is large (7+ letters)
        if length >= 7:
            row1 = MDBoxLayout(adaptive_size=True, spacing=dp(8), pos_hint={"center_x": 0.5})
            row2 = MDBoxLayout(adaptive_size=True, spacing=dp(8), pos_hint={"center_x": 0.5})
            mid = (length + 1) // 2

            for i, (t_id, char) in enumerate(self.scrambled_tiles):
                tile = LetterTile(
                    letter=char,
                    tile_id=t_id,
                    on_click_callback=self.on_scrambled_tile_click,
                    is_assembled=False,
                )
                tile.size = (tile_w, tile_h)
                self.tile_widgets[t_id] = tile
                if i < mid:
                    row1.add_widget(tile)
                else:
                    row2.add_widget(tile)

            box.add_widget(row1)
            box.add_widget(row2)
        else:
            row = MDBoxLayout(adaptive_size=True, spacing=dp(8), pos_hint={"center_x": 0.5})
            for t_id, char in self.scrambled_tiles:
                tile = LetterTile(
                    letter=char,
                    tile_id=t_id,
                    on_click_callback=self.on_scrambled_tile_click,
                    is_assembled=False,
                )
                tile.size = (tile_w, tile_h)
                self.tile_widgets[t_id] = tile
                row.add_widget(tile)
            box.add_widget(row)

    def render_assembly_tiles(self):
        """Render the chosen letters in the assembly area."""
        if not hasattr(self.ids, "assembly_box"):
            return

        box = self.ids.assembly_box
        box.clear_widgets()
        self.assembled_tile_widgets.clear()

        length = len(self.target_word)
        tile_w = dp(40) if length >= 8 else (dp(46) if length >= 6 else dp(52))
        tile_h = dp(46) if length >= 8 else (dp(50) if length >= 6 else dp(56))

        # Update placeholder indicators
        if hasattr(self.ids, "assembly_placeholder"):
            if not self.assembled_tiles:
                self.ids.assembly_placeholder.text = "  ".join(["_"] * length)
                self.ids.assembly_placeholder.opacity = 0.5
            else:
                self.ids.assembly_placeholder.text = ""
                self.ids.assembly_placeholder.opacity = 0.0

        if self.assembled_tiles:
            row = MDBoxLayout(adaptive_size=True, spacing=dp(6), pos_hint={"center_x": 0.5})
            for t_id, char in self.assembled_tiles:
                tile = LetterTile(
                    letter=char,
                    tile_id=t_id,
                    on_click_callback=self.on_assembled_tile_click,
                    is_assembled=True,
                )
                tile.size = (tile_w, tile_h)
                self.assembled_tile_widgets.append(tile)
                row.add_widget(tile)
            box.add_widget(row)

    def on_scrambled_tile_click(self, tile: LetterTile):
        """Move clicked tile from scrambled pool to assembly area."""
        if self.is_correct_state or tile.disabled:
            return

        tile.disabled = True
        tile.opacity = 0.28

        self.assembled_tiles.append((tile.tile_id, tile.letter))
        self.assembled_word = "".join(c for _, c in self.assembled_tiles)
        self.render_assembly_tiles()

        if not self.is_correct_state:
            self.set_banner_neutral()

    def on_assembled_tile_click(self, tile: LetterTile):
        """Return clicked assembled tile back to the scrambled pool."""
        if self.is_correct_state:
            return

        # Remove tile from assembled list
        for idx, (t_id, _) in enumerate(self.assembled_tiles):
            if t_id == tile.tile_id:
                self.assembled_tiles.pop(idx)
                break

        # Re-enable in scrambled pool
        if tile.tile_id in self.tile_widgets:
            src = self.tile_widgets[tile.tile_id]
            src.disabled = False
            src.opacity = 1.0

        self.assembled_word = "".join(c for _, c in self.assembled_tiles)
        self.render_assembly_tiles()

        if not self.is_correct_state:
            self.set_banner_neutral()

    def clear_assembly(self):
        """Clear all letters from the assembly area and return them to the scrambled pool."""
        play_click()
        if self.is_correct_state:
            return

        for t_id, _ in self.assembled_tiles:
            if t_id in self.tile_widgets:
                self.tile_widgets[t_id].disabled = False
                self.tile_widgets[t_id].opacity = 1.0

        for t_id, widget in self.tile_widgets.items():
            widget.disabled = False
            widget.opacity = 1.0

        self.assembled_tiles.clear()
        self.assembled_word = ""
        self.render_assembly_tiles()
        self.set_banner_neutral()

    def shuffle_scrambled_pool(self):
        """Shuffle only the letters currently remaining in the scrambled pool."""
        play_click()
        if self.is_correct_state:
            return

        # Keep tiles in assembled list, shuffle remaining
        used_ids = {t_id for t_id, _ in self.assembled_tiles}
        available = [item for item in self.scrambled_tiles if item[0] not in used_ids]
        random.shuffle(available)

        # Recombine
        new_order = []
        avail_idx = 0
        for item in self.scrambled_tiles:
            if item[0] in used_ids:
                new_order.append(item)
            else:
                new_order.append(available[avail_idx])
                avail_idx += 1

        self.scrambled_tiles = new_order
        self.render_scrambled_tiles()
        # Restore disabled states for already used tiles
        for t_id in used_ids:
            if t_id in self.tile_widgets:
                self.tile_widgets[t_id].disabled = True
                self.tile_widgets[t_id].opacity = 0.28

    def submit_word(self):
        """Validate the assembled word against the target word."""
        if self.is_correct_state:
            return

        if not self.assembled_word:
            self.show_banner("⚠️ Tap letters above to assemble the word first!", banner_type="warning")
            return

        if self.assembled_word.upper() == self.target_word.upper():
            # SUCCESS
            self.is_correct_state = True
            play_sfx("success")
            app = MDApp.get_running_app()

            # Determine coins earned based on attempt count
            coins_awarded = self.calculate_coin_reward(self.attempts_count)

            # Award coins & advance stage in JsonStore immediately
            if hasattr(app, "player_data") and app.player_data is not None:
                app.player_data.add_coins(coins_awarded)
                app.player_data.advance_stage()
                self.coins_display = app.player_data.get_coins()

            next_stage = (
                app.player_data.get_current_stage()
                if hasattr(app, "player_data") and app.player_data is not None
                else self.current_stage_display + 1
            )

            attempt_label = (
                "1st attempt"
                if self.attempts_count == 1
                else ("2nd attempt" if self.attempts_count == 2 else f"{self.attempts_count} attempts")
            )

            # Hamster cheerleader celebratory positive comment
            self.hamster_comment = random.choice(SOLVE_COMMENTS)

            # Show celebration success banner
            self.show_banner(
                f"🎉 SOLVED! +{coins_awarded} Coins ({attempt_label})! Advancing to Stage {next_stage}...",
                banner_type="success",
            )

            # Trigger the multi-layered celebration solve animation and hamster victory hop
            self.play_solve_animation(coins_awarded)
            self.play_hamster_hop()

            # Prevent further input during transition
            if hasattr(self.ids, "btn_submit"):
                self.ids.btn_submit.disabled = True
            if hasattr(self.ids, "btn_clear"):
                self.ids.btn_clear.disabled = True

            # Load the next stage after celebration delay
            Clock.schedule_once(lambda dt: self.advance_to_next_stage(), 1.8)
        else:
            # INCORRECT
            play_sfx("wrong")
            self.attempts_count += 1
            self.potential_reward = self.calculate_coin_reward(self.attempts_count)

            # Activate Hint Notification: Red "1" badge appears on the Hint button ONLY on wrong word!
            max_available = min(5, len(self.hints_list))
            if self.unlocked_hints_count < max_available:
                self.has_unread_hint = True
                self.hamster_comment = random.choice(WRONG_ATTEMPT_COMMENTS)
            else:
                self.has_unread_hint = False
                self.hamster_comment = random.choice(ALL_HINTS_COMMENTS)

            self.show_banner(
                f"❌ '{self.assembled_word}' is incorrect! Attempt #{self.attempts_count} (Reward now: {self.potential_reward} coins). Try again!",
                banner_type="error",
            )

    def play_solve_animation(self, coins_awarded: int):
        """Trigger celebratory animations right after the player solves the stage."""
        app = MDApp.get_running_app()

        # 1. Assembled Letter Cards Hop Wave & Emerald Victory Glow
        for idx, tile in enumerate(self.assembled_tile_widgets):
            orig_y = tile.y
            anim = (
                Animation(y=orig_y + dp(14), md_bg_color=[0.14, 0.72, 0.36, 1.0], duration=0.14, t="out_quad")
                + Animation(y=orig_y, duration=0.18, t="out_bounce")
            )
            Clock.schedule_once(lambda dt, a=anim, w=tile: a.start(w), idx * 0.07)

        # 2. Coin Counter Golden Glow Flash Pulse
        if hasattr(self.ids, "coin_badge_card"):
            badge = self.ids.coin_badge_card
            orig_bg = [0.22, 0.15, 0.09, 0.90]
            anim_coin = (
                Animation(md_bg_color=[1.0, 0.82, 0.15, 0.85], duration=0.2, t="out_quad")
                + Animation(md_bg_color=orig_bg, duration=0.4, t="in_quad")
            )
            anim_coin.start(badge)

        # 3. Banner Elastic Pop
        if hasattr(self.ids, "banner_card"):
            banner = self.ids.banner_card
            anim_banner = (
                Animation(opacity=0.3, duration=0.06)
                + Animation(opacity=1.0, duration=0.22, t="out_quad")
            )
            anim_banner.start(banner)

        # 4. Floating Victory Reward Popup (+10 Coins / +7 Coins)
        if hasattr(self.ids, "reward_float_badge"):
            float_badge = self.ids.reward_float_badge
            float_badge.disabled = False
            if hasattr(self.ids, "reward_float_text"):
                self.ids.reward_float_text.text = f"+{coins_awarded} COINS!"
            float_badge.opacity = 0.0
            anim_float = (
                Animation(opacity=1.0, duration=0.25, t="out_back")
                + Animation(opacity=1.0, duration=0.9)
                + Animation(opacity=0.0, duration=0.4, t="out_quad")
            )
            anim_float.bind(on_complete=lambda *args: setattr(float_badge, "disabled", True))
            anim_float.start(float_badge)

    def advance_to_next_stage(self):
        """Callback to load the next stage after success delay."""
        app = MDApp.get_running_app()
        if hasattr(self.ids, "reward_float_badge"):
            self.ids.reward_float_badge.disabled = True
            self.ids.reward_float_badge.opacity = 0.0
        next_stage = self.current_stage_display + 1
        if hasattr(app, "player_data") and app.player_data is not None:
            next_stage = app.player_data.get_current_stage()
        self.load_stage(next_stage)

    def show_banner(self, message: str, banner_type: str = "neutral"):
        """Display feedback message with appropriate theme colors."""
        self.banner_text = message
        if banner_type == "success":
            # Emerald green
            self.banner_bg_color = [0.12, 0.62, 0.32, 1.0]
            self.banner_text_color = [1.0, 1.0, 1.0, 1.0]
        elif banner_type == "error":
            # Vibrant crimson / red
            self.banner_bg_color = [0.82, 0.22, 0.22, 1.0]
            self.banner_text_color = [1.0, 1.0, 1.0, 1.0]
        elif banner_type == "warning":
            # Amber
            self.banner_bg_color = [0.85, 0.55, 0.12, 1.0]
            self.banner_text_color = [1.0, 1.0, 1.0, 1.0]
        else:
            # Neutral warm wood bark
            self.banner_bg_color = [0.22, 0.15, 0.09, 0.92]
            self.banner_text_color = [0.96, 0.92, 0.84, 1.0]

    def on_back_to_map(self):
        """Play click sound and return player to MapScreen."""
        play_click()
        app = MDApp.get_running_app()
        app.root.current = "map_screen"

    def set_banner_neutral(self):
        """Reset banner to default gameplay guidance."""
        self.show_banner(
            f"Read the clue and unscramble the {self.word_length_display}-letter word!",
            banner_type="neutral",
        )
