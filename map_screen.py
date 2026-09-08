"""MapScreen Module for Whack-A-Word_Ham.

Implements a vertical progression world map featuring 30 winding zig-zag stage nodes,
active avatar marker placement, milestone tiers (Stages 10, 20, 30), and seamless stage loading.
"""

import math
import os
from typing import Dict, List, Optional, Tuple

from kivy.animation import Animation
from kivy.clock import Clock
from kivy.core.window import Window
from kivy.metrics import dp
# pyrefly: ignore [missing-import]
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


class StageNodeButton(ButtonBehavior, MDRelativeLayout):
    """Circular stage node button on the vertical progression map.

    States:
    - 'completed' (node < current_stage): Forest green, disabled
    - 'active'    (node == current_stage): Vibrant orange, enabled, avatar token above
    - 'locked'    (node > current_stage): Slate stone grey, disabled
    - Milestones (10, 20, 30): Visually larger diameter with golden crest
    """

    stage_number = NumericProperty(1)
    is_milestone = BooleanProperty(False)
    node_state = StringProperty("locked")  # 'completed', 'active', 'locked'

    node_bg_color = ColorProperty([0.26, 0.24, 0.22, 0.82])
    node_border_color = ColorProperty([0.42, 0.38, 0.34, 0.65])
    node_text_color = ColorProperty([0.72, 0.68, 0.62, 0.80])
    node_diameter = NumericProperty(dp(56))

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.bind(node_state=self._update_appearance)
        self.bind(is_milestone=self._update_appearance)
        self._update_appearance()

    def _update_appearance(self, *args):
        """Update node colors and sizing according to state and milestone status."""
        if self.is_milestone:
            self.node_diameter = dp(76)
        else:
            self.node_diameter = dp(56)

        if self.node_state == "completed":
            self.node_bg_color = [0.14, 0.64, 0.28, 0.98]
            self.node_border_color = [0.38, 0.88, 0.48, 1.0]
            self.node_text_color = [1.0, 1.0, 1.0, 1.0]
        elif self.node_state == "active":
            self.node_bg_color = [0.96, 0.54, 0.12, 1.0]
            self.node_border_color = [1.0, 0.88, 0.35, 1.0]
            self.node_text_color = [1.0, 1.0, 1.0, 1.0]
        else:  # locked
            self.node_bg_color = [0.26, 0.24, 0.22, 0.82]
            self.node_border_color = [0.42, 0.38, 0.34, 0.65]
            self.node_text_color = [0.72, 0.68, 0.62, 0.80]

    def on_touch_down(self, touch):
        if not self.collide_point(*touch.pos):
            return False
        # Only the active node is enabled and clickable!
        # Completed (< current_stage) and locked (> current_stage) nodes are DISABLED
        if self.node_state != "active":
            return True
        if touch.is_mouse_scrolling or self in touch.ud:
            return False
        touch.grab(self)
        touch.ud[self] = True
        self.last_touch = touch
        self.state = "down"
        play_click()
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


Factory.register("StageNodeButton", cls=StageNodeButton)


class MapScreen(MDScreen):
    """Vertical progression map screen featuring 30 winding stage nodes and hamster avatar token."""

    current_stage = NumericProperty(1)
    coins_display = NumericProperty(0)
    equipped_overlay_source = StringProperty("assets/empty.png")
    total_stages = NumericProperty(30)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.node_widgets: Dict[int, StageNodeButton] = {}
        self.path_drawn = False
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
                self.current_stage = max(1, min(self.total_stages, app.player_data.get_current_stage()))
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

        # Immediate scroll on entry, then re-verify after layout
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
        self.current_stage = max(1, min(self.total_stages, int(value)))
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
    def get_node_rel_pos(stage: int) -> Tuple[float, float]:
        """Compute (rel_x, rel_y) on the winding zig-zag progression path."""
        # Stage 1 at bottom (rel_y = 0.04), Stage 30 at top (rel_y = 0.94)
        rel_y = 0.04 + (stage - 1) * (0.90 / 29.0)
        # Sinusoidal meandering S-curve across center 0.50
        rel_x = 0.50 + 0.28 * math.sin((stage - 1) * 0.80)
        return rel_x, rel_y

    def build_or_update_map(self):
        """Construct or update the 30 circular stage nodes on the float layout."""
        layout = self.ids.get("map_path_layout")
        if not layout:
            return

        active_stage = int(self.current_stage)

        # Build nodes if not already created
        if not self.node_widgets:
            for s in range(1, self.total_stages + 1):
                is_milestone = (s in [10, 20, 30])
                rel_x, rel_y = self.get_node_rel_pos(s)

                node = StageNodeButton(
                    stage_number=s,
                    is_milestone=is_milestone,
                    pos_hint={"center_x": rel_x, "center_y": rel_y},
                )
                node.bind(on_release=lambda instance, st=s: self.on_node_clicked(instance))
                layout.add_widget(node)
                self.node_widgets[s] = node

        app = MDApp.get_running_app()
        actual_stage = (
            app.player_data.get_current_stage()
            if (hasattr(app, "player_data") and app.player_data is not None)
            else active_stage
        )

        # Update node states
        for s, node in self.node_widgets.items():
            if s < active_stage:
                node.node_state = "completed"
                node.stage_number = s
            elif s == active_stage:
                node.node_state = "active"
                node.stage_number = actual_stage if actual_stage >= self.total_stages else s
            else:
                node.node_state = "locked"
                node.stage_number = s

        # Position avatar token over active node
        self.update_avatar_token_position(active_stage)
        # Redraw winding connecting trail
        Clock.schedule_once(lambda dt: self.draw_connecting_path(), 0.05)

    def update_avatar_token_position(self, active_stage: int):
        """Position the Hamster Avatar Token directly on top of the active node."""
        token = self.ids.get("hamster_map_token")
        if not token or active_stage not in self.node_widgets:
            return

        rel_x, rel_y = self.get_node_rel_pos(active_stage)
        is_milestone = (active_stage in [10, 20, 30])
        # Position token slightly above the node
        y_offset = 0.022 if is_milestone else 0.018
        token.pos_hint = {"center_x": rel_x, "center_y": rel_y + y_offset}

        # Start cute bobbing idle animation
        if self._bobbing_anim:
            self._bobbing_anim.stop(token)

        anim = (
            Animation(pos_hint={"center_x": rel_x, "center_y": rel_y + y_offset + 0.003}, duration=0.6, t="in_out_sine")
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
                    x1_rel, y1_rel = self.get_node_rel_pos(s)
                    x2_rel, y2_rel = self.get_node_rel_pos(s + 1)

                    p1_x = layout.x + x1_rel * layout.width
                    p1_y = layout.y + y1_rel * layout.height
                    p2_x = layout.x + x2_rel * layout.width
                    p2_y = layout.y + y2_rel * layout.height

                    # Draw 4 small stepping stones along the line between nodes
                    steps = 4
                    for step in range(1, steps):
                        frac = step / float(steps)
                        sx = p1_x + (p2_x - p1_x) * frac
                        sy = p1_y + (p2_y - p1_y) * frac

                        # Completed or active trail: golden amber stepping stone
                        if s < active_stage:
                            Color(0.88, 0.72, 0.32, 0.85)
                            stone_r = dp(5.0)
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
        _, rel_y = self.get_node_rel_pos(active_stage)

        total_h = layout.height
        view_h = scroll.height if scroll.height > dp(200) else Window.height
        if total_h <= view_h:
            return

        # Target pixel y on content
        target_y = rel_y * total_h
        target_offset = target_y - (view_h / 2.0)
        max_scroll = total_h - view_h
        target_scroll_y = max(0.0, min(1.0, target_offset / max_scroll))

        if animate:
            anim = Animation(scroll_y=target_scroll_y, duration=0.35, t="out_quad")
            anim.start(scroll)
        else:
            scroll.scroll_y = target_scroll_y

    def on_node_clicked(self, node_widget: StageNodeButton):
        """Handle tap on a stage node: only active stage launches gameplay."""
        try:
            if node_widget.node_state != "active":
                return

            stage_num = int(node_widget.stage_number)
            app = MDApp.get_running_app()
            if hasattr(app, "player_data") and app.player_data is not None:
                actual_stage = app.player_data.get_current_stage()
                if actual_stage >= self.total_stages and node_widget.stage_number >= self.total_stages:
                    stage_num = actual_stage

            stage_screen = app.root.get_screen("stage_mode")
            if stage_screen:
                stage_screen.target_stage_to_load = stage_num
            app.root.current = "stage_mode"
        except Exception as e:
            print(f"[MapScreen] Error launching stage_mode: {e}")

    def on_back_to_menu(self):
        """Return to main menu screen."""
        try:
            play_click()
            app = MDApp.get_running_app()
            app.root.current = "main_menu"
        except Exception as e:
            print(f"[MapScreen] Error returning to menu: {e}")

    def open_settings(self):
        """Open the Audio Settings dialog modal."""
        from settings_dialog import SettingsDialog
        if not hasattr(self, "_settings_dialog") or not self._settings_dialog:
            self._settings_dialog = SettingsDialog()
        self._settings_dialog.open(self)
