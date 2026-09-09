"""MapScreen Module for Whack-A-Word_Ham.

Implements an endlessly expandable vertical progression world map featuring:
- Dynamic 30-stage chunk generation (1-30, 31-60, 61-90, 91-120, etc.)
- 5 unique cycling world themes (Woodland Forest, Sunny Sunflower Meadow, Cozy Kitchen Pantry,
  Glowing Underground Burrow, Golden Autumn Acorn Forest)
- Chapter entrance banners, milestone tiers, stepping-stone path drawing,
- Centered hamster avatar tracking, and smooth level launching.
"""

import math
import os
from typing import Any, Dict, List, Optional, Tuple

from kivy.animation import Animation
from kivy.clock import Clock
from kivy.core.window import Window
from kivy.metrics import dp
from kivy.properties import (
    BooleanProperty,
    ColorProperty,
    ListProperty,
    NumericProperty,
    ObjectProperty,
    StringProperty,
)
from kivy.uix.behaviors import ButtonBehavior
from kivy.graphics import Color, Ellipse, Line
from kivy.factory import Factory
from kivymd.app import MDApp
from kivymd.uix.relativelayout import MDRelativeLayout
from kivymd.uix.screen import MDScreen
from avatar_shop import ACCESSORIES
from audio_manager import play_bgm, play_click


# -----------------------------------------------------------------------------
# 5 Cycling World Themes (30 Levels per Theme)
# -----------------------------------------------------------------------------
MAP_THEMES: List[Dict[str, Any]] = [
    {
        "id": "woodland_forest",
        "name": "Woodland Forest",
        "icon": "tree",
        "tagline": "Whispering pines & shaded mossy trails",
        "completed_color": [0.14, 0.64, 0.28, 0.98],
        "completed_border": [0.38, 0.88, 0.48, 1.0],
        "active_color": [0.96, 0.54, 0.12, 1.0],
        "active_border": [1.0, 0.88, 0.35, 1.0],
        "stone_color": [0.88, 0.72, 0.32, 0.85],
        "stone_completed_color": [0.88, 0.72, 0.32, 0.95],
        "banner_bg": [0.24, 0.16, 0.10, 0.95],
        "banner_border": [0.88, 0.72, 0.32, 0.85],
    },
    {
        "id": "sunflower_meadow",
        "name": "Sunny Sunflower Meadow",
        "icon": "flower",
        "tagline": "Golden petals swaying in the sunlit breeze",
        "completed_color": [0.85, 0.60, 0.10, 0.98],
        "completed_border": [1.0, 0.82, 0.28, 1.0],
        "active_color": [0.98, 0.72, 0.14, 1.0],
        "active_border": [1.0, 0.92, 0.45, 1.0],
        "stone_color": [0.95, 0.80, 0.25, 0.85],
        "stone_completed_color": [1.0, 0.86, 0.28, 0.95],
        "banner_bg": [0.32, 0.22, 0.06, 0.95],
        "banner_border": [1.0, 0.85, 0.25, 0.90],
    },
    {
        "id": "kitchen_pantry",
        "name": "Cozy Kitchen Pantry",
        "icon": "cupcake",
        "tagline": "Warm biscuit crusts & sweet cinnamon spice",
        "completed_color": [0.76, 0.38, 0.20, 0.98],
        "completed_border": [0.94, 0.58, 0.38, 1.0],
        "active_color": [0.94, 0.46, 0.22, 1.0],
        "active_border": [1.0, 0.74, 0.50, 1.0],
        "stone_color": [0.88, 0.58, 0.35, 0.85],
        "stone_completed_color": [0.96, 0.68, 0.42, 0.95],
        "banner_bg": [0.28, 0.16, 0.10, 0.95],
        "banner_border": [0.95, 0.68, 0.45, 0.85],
    },
    {
        "id": "underground_burrow",
        "name": "Glowing Underground Burrow",
        "icon": "star-four-points",
        "tagline": "Bioluminescent fungi & secret gem caverns",
        "completed_color": [0.12, 0.56, 0.68, 0.98],
        "completed_border": [0.30, 0.80, 0.92, 1.0],
        "active_color": [0.20, 0.74, 0.86, 1.0],
        "active_border": [0.52, 0.92, 0.98, 1.0],
        "stone_color": [0.35, 0.84, 0.92, 0.85],
        "stone_completed_color": [0.45, 0.92, 0.98, 0.95],
        "banner_bg": [0.10, 0.18, 0.24, 0.95],
        "banner_border": [0.45, 0.90, 0.96, 0.85],
    },
    {
        "id": "autumn_forest",
        "name": "Golden Autumn Acorn Forest",
        "icon": "leaf-maple",
        "tagline": "Crisp fallen maple leaves & bountiful acorn groves",
        "completed_color": [0.80, 0.28, 0.12, 0.98],
        "completed_border": [0.96, 0.50, 0.30, 1.0],
        "active_color": [0.95, 0.42, 0.10, 1.0],
        "active_border": [1.0, 0.70, 0.28, 1.0],
        "stone_color": [0.96, 0.62, 0.18, 0.85],
        "stone_completed_color": [1.0, 0.72, 0.22, 0.95],
        "banner_bg": [0.30, 0.14, 0.08, 0.95],
        "banner_border": [1.0, 0.70, 0.25, 0.85],
    },
]


def get_theme_for_stage(stage: int) -> Dict[str, Any]:
    """Return the theme configuration dictionary for a given stage number."""
    theme_idx = ((max(1, stage) - 1) // 30) % len(MAP_THEMES)
    return MAP_THEMES[theme_idx]


def get_max_stages_for_level(current_stage: int) -> int:
    """Calculate the total stages to show on the map (expands in chunks of 30).

    Levels 1-29 -> 30 stages
    Levels 30-59 -> 60 stages
    Levels 60-89 -> 90 stages
    Levels 90-119 -> 120 stages, etc.
    """
    st = max(1, current_stage)
    if st < 30:
        return 30
    return ((st // 30) + 1) * 30


# -----------------------------------------------------------------------------
# Chapter Banner Archway Card
# -----------------------------------------------------------------------------
class ChapterBannerCard(MDRelativeLayout):
    """Decorative chapter header archway placed on the map at the start of each theme."""

    chapter_num = NumericProperty(1)
    chapter_name = StringProperty("")
    chapter_icon = StringProperty("tree")
    chapter_range = StringProperty("")
    theme_bg = ColorProperty([0.24, 0.16, 0.10, 0.95])
    theme_border = ColorProperty([0.88, 0.72, 0.32, 0.85])


Factory.register("ChapterBannerCard", cls=ChapterBannerCard)


# -----------------------------------------------------------------------------
# Circular Stage Node Button
# -----------------------------------------------------------------------------
class StageNodeButton(ButtonBehavior, MDRelativeLayout):
    """Circular stage node button on the vertical progression map."""

    stage_number = NumericProperty(1)
    is_milestone = BooleanProperty(False)
    is_grand_milestone = BooleanProperty(False)
    node_state = StringProperty("locked")  # 'completed', 'active', 'locked'
    theme_id = StringProperty("woodland_forest")

    node_bg_color = ColorProperty([0.26, 0.24, 0.22, 0.82])
    node_border_color = ColorProperty([0.42, 0.38, 0.34, 0.65])
    node_text_color = ColorProperty([0.72, 0.68, 0.62, 0.80])
    node_diameter = NumericProperty(dp(56))

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.bind(node_state=self._update_appearance)
        self.bind(is_milestone=self._update_appearance)
        self.bind(is_grand_milestone=self._update_appearance)
        self.bind(theme_id=self._update_appearance)
        self._update_appearance()

    def _update_appearance(self, *args):
        """Update node colors and sizing according to state, milestone status, and theme."""
        if self.is_grand_milestone:
            self.node_diameter = dp(84)
        elif self.is_milestone:
            self.node_diameter = dp(72)
        else:
            self.node_diameter = dp(56)

        theme = get_theme_for_stage(self.stage_number)

        if self.node_state == "completed":
            self.node_bg_color = theme.get("completed_color", [0.14, 0.64, 0.28, 0.98])
            self.node_border_color = theme.get("completed_border", [0.38, 0.88, 0.48, 1.0])
            self.node_text_color = [1.0, 1.0, 1.0, 1.0]
        elif self.node_state == "active":
            self.node_bg_color = theme.get("active_color", [0.96, 0.54, 0.12, 1.0])
            self.node_border_color = theme.get("active_border", [1.0, 0.88, 0.35, 1.0])
            self.node_text_color = [1.0, 1.0, 1.0, 1.0]
        else:  # locked
            self.node_bg_color = [0.26, 0.24, 0.22, 0.82]
            self.node_border_color = [0.42, 0.38, 0.34, 0.65]
            self.node_text_color = [0.72, 0.68, 0.62, 0.80]

    def on_touch_down(self, touch):
        try:
            if not self.collide_point(*touch.pos):
                if self.parent and hasattr(self.parent, "to_widget"):
                    p_pos = self.parent.to_widget(*touch.pos)
                    if not self.collide_point(*p_pos):
                        return False
                else:
                    return False
            # Only the active node is enabled and clickable!
            if self.node_state != "active":
                return True
            if getattr(touch, "is_mouse_scrolling", False) or self in touch.ud:
                return False
            touch.grab(self)
            touch.ud[self] = True
            self.last_touch = touch
            self.state = "down"
            play_click()
            self.dispatch("on_press")
            return True
        except Exception as e:
            print(f"[StageNodeButton] touch_down error: {e}")
            return False

    def on_touch_up(self, touch):
        try:
            if touch.grab_current is not self:
                return False
            touch.ungrab(self)
            self.last_touch = touch
            self.state = "normal"

            is_hit = self.collide_point(*touch.pos)
            if not is_hit and self.parent and hasattr(self.parent, "to_widget"):
                p_pos = self.parent.to_widget(*touch.pos)
                is_hit = self.collide_point(*p_pos)

            if is_hit:
                self.dispatch("on_release")
            return True
        except Exception as e:
            print(f"[StageNodeButton] touch_up error: {e}")
            return False


Factory.register("StageNodeButton", cls=StageNodeButton)


# -----------------------------------------------------------------------------
# Main MapScreen Class
# -----------------------------------------------------------------------------
class MapScreen(MDScreen):
    """Endlessly expandable vertical progression map screen."""

    current_stage = NumericProperty(1)
    coins_display = NumericProperty(0)
    equipped_overlay_source = StringProperty("assets/empty.png")
    total_stages = NumericProperty(30)

    current_theme_name = StringProperty("Woodland Forest")
    current_theme_icon = StringProperty("tree")
    current_theme_tagline = StringProperty("Whispering pines & shaded mossy trails")

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.node_widgets: Dict[int, StageNodeButton] = {}
        self.chapter_banners: Dict[int, ChapterBannerCard] = {}
        self._bobbing_anim = None

    def on_enter(self, *args):
        """Called automatically when player enters MapScreen."""
        super().on_enter(*args)
        try:
            play_bgm("main")
        except Exception:
            pass

        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            try:
                app.player_data.load()
                actual_stage = app.player_data.get_current_stage()
                self.current_stage = max(1, actual_stage)
                self.total_stages = get_max_stages_for_level(self.current_stage)

                theme = get_theme_for_stage(self.current_stage)
                self.current_theme_name = theme["name"]
                self.current_theme_icon = theme["icon"]
                self.current_theme_tagline = theme["tagline"]

                self.coins_display = app.player_data.get_coins()
                app.player_data.bind(
                    current_stage=self._on_stage_changed,
                    coins=self._on_coins_changed,
                )
            except Exception as e:
                print(f"[MapScreen] Warning: Error syncing player_data: {e}")

        try:
            self.update_hamster_accessory()
        except Exception as e:
            print(f"[MapScreen] Warning: Error updating accessory: {e}")

        try:
            self.build_or_update_map()
        except Exception as e:
            print(f"[MapScreen] Warning: Error building map: {e}")

        # Immediate scroll on entry, then re-verify after layout settling
        try:
            self.scroll_to_active_stage(animate=False)
            Clock.schedule_once(lambda dt: self.scroll_to_active_stage(animate=False), 0.08)
        except Exception as e:
            print(f"[MapScreen] Warning: Error scrolling map: {e}")

    def on_leave(self, *args):
        """Clean up animations on leaving."""
        super().on_leave(*args)
        if self._bobbing_anim:
            token = self.ids.get("hamster_map_token")
            if token:
                self._bobbing_anim.stop(token)

    def _on_stage_changed(self, instance, value):
        self.current_stage = max(1, int(value))
        self.total_stages = get_max_stages_for_level(self.current_stage)
        theme = get_theme_for_stage(self.current_stage)
        self.current_theme_name = theme["name"]
        self.current_theme_icon = theme["icon"]
        self.current_theme_tagline = theme["tagline"]

        self.build_or_update_map()
        Clock.schedule_once(lambda dt: self.scroll_to_active_stage(animate=True), 0.05)

    def _on_coins_changed(self, instance, value):
        self.coins_display = int(value)

    def update_hamster_accessory(self):
        """Sync equipped accessory from player_data."""
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

    @staticmethod
    def get_node_rel_pos(stage: int, total_stages: int = 30) -> Tuple[float, float]:
        """Compute (rel_x, rel_y) on the winding zig-zag progression path."""
        total = max(2, total_stages)
        # Stage 1 at bottom margin (rel_y = 0.025), Stage total at top margin (rel_y = 0.96)
        rel_y = 0.025 + (stage - 1) * (0.935 / float(total - 1))
        # Sinusoidal meandering S-curve across center 0.50
        rel_x = 0.50 + 0.28 * math.sin((stage - 1) * 0.80)
        return rel_x, rel_y

    def build_or_update_map(self):
        """Construct or update the stage nodes and chapter banners on the float layout."""
        layout = self.ids.get("map_path_layout")
        if not layout:
            return

        active_stage = int(self.current_stage)
        self.total_stages = get_max_stages_for_level(active_stage)

        # Dynamic height: 105 dp per stage
        layout.height = dp(105 * self.total_stages)

        # Update theme properties
        theme = get_theme_for_stage(active_stage)
        self.current_theme_name = theme["name"]
        self.current_theme_icon = theme["icon"]
        self.current_theme_tagline = theme["tagline"]

        # 1. Build / update Stage Node Buttons
        for s in range(1, self.total_stages + 1):
            rel_x, rel_y = self.get_node_rel_pos(s, self.total_stages)
            is_milestone = (s % 10 == 0)
            is_grand_milestone = (s % 30 == 0)
            node_theme = get_theme_for_stage(s)

            if s not in self.node_widgets:
                node = StageNodeButton(
                    stage_number=s,
                    is_milestone=is_milestone,
                    is_grand_milestone=is_grand_milestone,
                    theme_id=node_theme["id"],
                    pos_hint={"center_x": rel_x, "center_y": rel_y},
                )
                node.bind(on_release=lambda instance, st=s: self.on_node_clicked(instance))
                layout.add_widget(node)
                self.node_widgets[s] = node
            else:
                node = self.node_widgets[s]
                node.stage_number = s
                node.is_milestone = is_milestone
                node.is_grand_milestone = is_grand_milestone
                node.theme_id = node_theme["id"]
                node.pos_hint = {"center_x": rel_x, "center_y": rel_y}

            # State assignment
            if s < active_stage:
                node.node_state = "completed"
            elif s == active_stage:
                node.node_state = "active"
            else:
                node.node_state = "locked"

        # 2. Build Chapter Entrance Banners (for Chapter 2, Chapter 3, etc.)
        num_chapters = self.total_stages // 30
        for ch in range(1, num_chapters + 1):
            ch_start_stage = (ch - 1) * 30 + 1
            ch_end_stage = ch * 30
            ch_theme = get_theme_for_stage(ch_start_stage)

            if ch == 1:
                # Chapter 1 banner at the very bottom
                banner_rel_y = 0.008
            else:
                # Place banner midway between previous stage (ch_start - 1) and ch_start
                prev_y = self.get_node_rel_pos(ch_start_stage - 1, self.total_stages)[1]
                curr_y = self.get_node_rel_pos(ch_start_stage, self.total_stages)[1]
                banner_rel_y = (prev_y + curr_y) / 2.0

            if ch not in self.chapter_banners:
                banner = ChapterBannerCard(
                    chapter_num=ch,
                    chapter_name=ch_theme["name"],
                    chapter_icon=ch_theme["icon"],
                    chapter_range=f"Stages {ch_start_stage} – {ch_end_stage}",
                    theme_bg=ch_theme.get("banner_bg", [0.24, 0.16, 0.10, 0.95]),
                    theme_border=ch_theme.get("banner_border", [0.88, 0.72, 0.32, 0.85]),
                    pos_hint={"center_x": 0.50, "center_y": banner_rel_y},
                )
                layout.add_widget(banner)
                self.chapter_banners[ch] = banner
            else:
                banner = self.chapter_banners[ch]
                banner.chapter_name = ch_theme["name"]
                banner.chapter_icon = ch_theme["icon"]
                banner.chapter_range = f"Stages {ch_start_stage} – {ch_end_stage}"
                banner.theme_bg = ch_theme.get("banner_bg", [0.24, 0.16, 0.10, 0.95])
                banner.theme_border = ch_theme.get("banner_border", [0.88, 0.72, 0.32, 0.85])
                banner.pos_hint = {"center_x": 0.50, "center_y": banner_rel_y}

        # Position avatar token over active node
        self.update_avatar_token_position(active_stage)
        # Redraw connecting trail
        Clock.schedule_once(lambda dt: self.draw_connecting_path(), 0.05)

    build_map = build_or_update_map

    def update_avatar_token_position(self, active_stage: int):
        """Position the Hamster Avatar Token directly on top of the active node."""
        token = self.ids.get("hamster_map_token")
        if not token or active_stage not in self.node_widgets:
            return

        rel_x, rel_y = self.get_node_rel_pos(active_stage, self.total_stages)
        is_milestone = (active_stage % 10 == 0)
        y_offset = 0.016 if is_milestone else 0.014
        token.pos_hint = {"center_x": rel_x, "center_y": rel_y + y_offset}

        # Start bobbing animation
        if self._bobbing_anim:
            self._bobbing_anim.stop(token)

        anim = (
            Animation(pos_hint={"center_x": rel_x, "center_y": rel_y + y_offset + 0.002}, duration=0.6, t="in_out_sine")
            + Animation(pos_hint={"center_x": rel_x, "center_y": rel_y + y_offset}, duration=0.6, t="in_out_sine")
        )
        anim.repeat = True
        self._bobbing_anim = anim
        anim.start(token)

    def draw_connecting_path(self):
        """Draw stepping stone path dots connecting consecutive stage nodes on canvas.before."""
        layout = self.ids.get("map_path_layout")
        if not layout or not self.node_widgets:
            return

        try:
            layout.canvas.before.clear()
            active_stage = int(self.current_stage)

            with layout.canvas.before:
                for s in range(1, self.total_stages):
                    x1_rel, y1_rel = self.get_node_rel_pos(s, self.total_stages)
                    x2_rel, y2_rel = self.get_node_rel_pos(s + 1, self.total_stages)

                    p1_x = layout.x + x1_rel * layout.width
                    p1_y = layout.y + y1_rel * layout.height
                    p2_x = layout.x + x2_rel * layout.width
                    p2_y = layout.y + y2_rel * layout.height

                    theme = get_theme_for_stage(s)

                    # Draw 4 stepping stones between consecutive nodes
                    steps = 4
                    for step in range(1, steps):
                        frac = step / float(steps)
                        sx = p1_x + (p2_x - p1_x) * frac
                        sy = p1_y + (p2_y - p1_y) * frac

                        if s < active_stage:
                            stone_col = theme.get("stone_completed_color", [0.88, 0.72, 0.32, 0.95])
                            Color(*stone_col)
                            stone_r = dp(5.0)
                        elif s == active_stage:
                            stone_col = theme.get("stone_color", [1.0, 0.85, 0.25, 0.90])
                            Color(*stone_col)
                            stone_r = dp(4.5)
                        else:
                            Color(0.35, 0.32, 0.30, 0.50)
                            stone_r = dp(4.0)

                        Ellipse(pos=(sx - stone_r, sy - stone_r), size=(stone_r * 2, stone_r * 2))
        except Exception as e:
            print(f"[MapScreen] Warning: Error drawing connecting path: {e}")

    def scroll_to_active_stage(self, animate: bool = False):
        """Center the MDScrollView on the active stage node."""
        scroll = self.ids.get("map_scroll")
        layout = self.ids.get("map_path_layout")
        if not scroll or not layout:
            return

        active_stage = int(self.current_stage)
        _, rel_y = self.get_node_rel_pos(active_stage, self.total_stages)

        total_h = layout.height
        view_h = scroll.height if scroll.height > dp(200) else Window.height
        if total_h <= view_h:
            return

        target_y = rel_y * total_h
        target_offset = target_y - (view_h / 2.0)
        max_scroll = max(1.0, total_h - view_h)
        target_scroll_y = max(0.0, min(1.0, target_offset / max_scroll))

        if animate:
            anim = Animation(scroll_y=target_scroll_y, duration=0.35, t="out_quad")
            anim.start(scroll)
        else:
            scroll.scroll_y = target_scroll_y

    center_on_active_stage = scroll_to_active_stage

    def on_node_clicked(self, node_widget: StageNodeButton):
        """Handle tap on a stage node: only active stage launches gameplay."""
        try:
            if node_widget.node_state != "active":
                return

            stage_num = int(node_widget.stage_number)
            app = MDApp.get_running_app()
            if hasattr(app, "player_data") and app.player_data is not None:
                actual_stage = app.player_data.get_current_stage()
                stage_num = max(1, actual_stage)

            stage_screen = app.root.get_screen("stage_mode")
            if stage_screen:
                stage_screen.target_stage_to_load = stage_num
            if hasattr(app, "switch_screen"):
                app.switch_screen("stage_mode")
            else:
                app.root.current = "stage_mode"
        except Exception as e:
            print(f"[MapScreen] Error launching stage_mode: {e}")

    def on_back_to_menu(self):
        """Return to main menu screen."""
        try:
            play_click()
            app = MDApp.get_running_app()
            if hasattr(app, "switch_screen"):
                app.switch_screen("main_menu")
            else:
                app.root.current = "main_menu"
        except Exception as e:
            print(f"[MapScreen] Error returning to menu: {e}")

    def open_settings(self):
        """Open the Audio Settings dialog modal."""
        try:
            from settings_dialog import SettingsDialog
            if not hasattr(self, "_settings_dialog") or not self._settings_dialog:
                self._settings_dialog = SettingsDialog()
            self._settings_dialog.open(self)
        except Exception as e:
            print(f"[MapScreen] Error opening settings: {e}")


Factory.register("MapScreen", cls=MapScreen)
