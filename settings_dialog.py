"""Audio Settings Dialog Module for Whack-A-Word-Ham.

Provides a tactile wood & forest themed modal overlay enabling players to:
- Dynamically adjust Background Music (BGM) volume with real-time audio update
- Dynamically adjust Sound Effects (SFX) volume with real-time audio update and preview
- Persist settings via PlayerDataManager
"""

from kivy.animation import Animation
from kivy.lang import Builder
from kivy.metrics import dp
from kivy.properties import NumericProperty
from kivy.uix.slider import Slider
from kivymd.app import MDApp
from kivymd.uix.relativelayout import MDRelativeLayout

from audio_manager import AudioManager, play_click

SETTINGS_DIALOG_KV = """
<SettingsDialog>:
    size_hint: (1, 1)
    pos_hint: {"center_x": 0.5, "center_y": 0.5}

    # Dimmed Backdrop
    Widget:
        id: backdrop
        size_hint: (1, 1)
        canvas:
            Color:
                rgba: [0.04, 0.03, 0.02, 0.78]
            Rectangle:
                pos: self.pos
                size: self.size

    # Centered Carved Wood Settings Plaque
    MDCard:
        id: card_container
        style: "elevated"
        theme_bg_color: "Custom"
        md_bg_color: [0.20, 0.14, 0.08, 0.98]
        line_color: [0.52, 0.36, 0.18, 0.95]
        line_width: dp(2.5)
        radius: [dp(22), dp(22), dp(22), dp(22)]
        size_hint: (None, None)
        size: [dp(350), dp(400)]
        pos_hint: {"center_x": 0.5, "center_y": 0.5}
        padding: [dp(20), dp(18), dp(20), dp(18)]

        MDBoxLayout:
            orientation: "vertical"
            spacing: dp(14)
            size_hint: (1, 1)

            # Header Row
            MDBoxLayout:
                adaptive_height: True
                spacing: dp(10)
                pos_hint: {"center_y": 0.5}

                MDIcon:
                    icon: "cog"
                    font_size: "26sp"
                    theme_icon_color: "Custom"
                    icon_color: [1.0, 0.82, 0.28, 1.0]
                    pos_hint: {"center_y": 0.5}

                MDBoxLayout:
                    orientation: "vertical"
                    adaptive_size: True
                    pos_hint: {"center_y": 0.5}

                    MDLabel:
                        text: "Audio Settings"
                        bold: True
                        font_style: "Title"
                        role: "medium"
                        theme_text_color: "Custom"
                        text_color: [1.0, 0.92, 0.80, 1.0]
                        adaptive_size: True

                    MDLabel:
                        text: "Customize game volume"
                        font_style: "Body"
                        role: "small"
                        theme_text_color: "Custom"
                        text_color: [0.80, 0.72, 0.60, 0.85]
                        adaptive_size: True

                Widget:

                MDIconButton:
                    icon: "close"
                    style: "filled"
                    theme_bg_color: "Custom"
                    md_bg_color: [0.28, 0.18, 0.10, 0.90]
                    theme_icon_color: "Custom"
                    icon_color: [1.0, 0.90, 0.80, 1.0]
                    on_release: root.close()
                    pos_hint: {"center_y": 0.5}

            # Divider line
            Widget:
                size_hint_y: None
                height: dp(1.5)
                canvas:
                    Color:
                        rgba: [0.45, 0.32, 0.18, 0.50]
                    Rectangle:
                        pos: self.pos
                        size: self.size

            # 1. Background Music (BGM) Control Box
            MDCard:
                style: "filled"
                theme_bg_color: "Custom"
                md_bg_color: [0.14, 0.09, 0.05, 0.85]
                radius: [dp(14), dp(14), dp(14), dp(14)]
                padding: [dp(14), dp(10), dp(14), dp(10)]
                adaptive_height: True
                pos_hint: {"center_x": 0.5}

                MDBoxLayout:
                    orientation: "vertical"
                    adaptive_height: True
                    spacing: dp(4)

                    MDBoxLayout:
                        adaptive_height: True
                        spacing: dp(6)

                        MDIcon:
                            icon: "music"
                            font_size: "18sp"
                            theme_icon_color: "Custom"
                            icon_color: [1.0, 0.78, 0.22, 1.0]
                            pos_hint: {"center_y": 0.5}

                        MDLabel:
                            text: "Background Music"
                            bold: True
                            font_style: "Label"
                            role: "large"
                            theme_text_color: "Custom"
                            text_color: [0.98, 0.94, 0.86, 1.0]
                            adaptive_size: True
                            pos_hint: {"center_y": 0.5}

                        Widget:

                        MDLabel:
                            text: str(int(root.bgm_volume_percent)) + "%"
                            bold: True
                            adaptive_size: True
                            font_style: "Label"
                            role: "large"
                            theme_text_color: "Custom"
                            text_color: [1.0, 0.82, 0.28, 1.0]
                            pos_hint: {"center_y": 0.5}

                    Slider:
                        id: bgm_slider
                        min: 0
                        max: 100
                        step: 1
                        value: root.bgm_volume_percent
                        size_hint_y: None
                        height: dp(34)
                        value_track: True
                        value_track_color: [0.96, 0.68, 0.18, 1.0]
                        cursor_size: (dp(20), dp(20))
                        on_value: root.on_bgm_slider_change(self.value)

            # 2. Sound Effects (SFX) Control Box
            MDCard:
                style: "filled"
                theme_bg_color: "Custom"
                md_bg_color: [0.14, 0.09, 0.05, 0.85]
                radius: [dp(14), dp(14), dp(14), dp(14)]
                padding: [dp(14), dp(10), dp(14), dp(10)]
                adaptive_height: True
                pos_hint: {"center_x": 0.5}

                MDBoxLayout:
                    orientation: "vertical"
                    adaptive_height: True
                    spacing: dp(4)

                    MDBoxLayout:
                        adaptive_height: True
                        spacing: dp(6)

                        MDIcon:
                            icon: "volume-high"
                            font_size: "18sp"
                            theme_icon_color: "Custom"
                            icon_color: [0.32, 0.85, 0.45, 1.0]
                            pos_hint: {"center_y": 0.5}

                        MDLabel:
                            text: "Sound Effects (SFX)"
                            bold: True
                            font_style: "Label"
                            role: "large"
                            theme_text_color: "Custom"
                            text_color: [0.98, 0.94, 0.86, 1.0]
                            adaptive_size: True
                            pos_hint: {"center_y": 0.5}

                        Widget:

                        MDLabel:
                            text: str(int(root.sfx_volume_percent)) + "%"
                            bold: True
                            adaptive_size: True
                            font_style: "Label"
                            role: "large"
                            theme_text_color: "Custom"
                            text_color: [0.42, 0.90, 0.52, 1.0]
                            pos_hint: {"center_y": 0.5}

                    Slider:
                        id: sfx_slider
                        min: 0
                        max: 100
                        step: 1
                        value: root.sfx_volume_percent
                        size_hint_y: None
                        height: dp(34)
                        value_track: True
                        value_track_color: [0.22, 0.76, 0.38, 1.0]
                        cursor_size: (dp(20), dp(20))
                        on_value: root.on_sfx_slider_change(self.value)
                        on_touch_up: root.on_sfx_slider_touch_up(self, args[1])

            Widget:

            # Done / Save Button
            MDButton:
                style: "filled"
                theme_bg_color: "Custom"
                md_bg_color: [0.28, 0.18, 0.10, 0.95]
                size_hint_x: 1
                height: dp(44)
                pos_hint: {"center_x": 0.5}
                on_release: root.close()

                MDButtonIcon:
                    icon: "check-bold"
                    theme_icon_color: "Custom"
                    icon_color: [1.0, 0.88, 0.35, 1.0]

                MDButtonText:
                    text: "DONE"
                    bold: True
                    theme_text_color: "Custom"
                    text_color: [1.0, 0.96, 0.90, 1.0]
"""

Builder.load_string(SETTINGS_DIALOG_KV)


class SettingsDialog(MDRelativeLayout):
    """Audio Settings modal dialog with BGM and SFX volume sliders."""

    bgm_volume_percent = NumericProperty(60)
    sfx_volume_percent = NumericProperty(80)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.opacity = 0.0
        self._is_open = False
        self._sync_with_current_volume()

    def _sync_with_current_volume(self):
        """Sync slider values with current player_data and AudioManager levels."""
        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            self.bgm_volume_percent = int(app.player_data.get_bgm_volume() * 100)
            self.sfx_volume_percent = int(app.player_data.get_sfx_volume() * 100)
        else:
            am = AudioManager.get_instance()
            self.bgm_volume_percent = int(am.get_bgm_volume() * 100)
            self.sfx_volume_percent = int(am.get_sfx_volume() * 100)

    def open(self, parent_widget=None):
        """Display the modal settings dialog with a smooth fade-in animation."""
        if self._is_open:
            return

        play_click()
        self._sync_with_current_volume()

        # Determine parent container
        target_parent = parent_widget
        if not target_parent:
            app = MDApp.get_running_app()
            target_parent = app.root

        if target_parent and self not in target_parent.children:
            target_parent.add_widget(self)

        self._is_open = True
        self.opacity = 0.0
        card = self.ids.get("card_container")
        if card:
            card.scale_value = 0.92

        anim = Animation(opacity=1.0, duration=0.20, t="out_quad")
        anim.start(self)

    def close(self):
        """Dismiss the modal settings dialog."""
        if not self._is_open:
            return

        play_click()
        self._is_open = False

        anim = Animation(opacity=0.0, duration=0.18, t="in_quad")

        def on_finish(*args):
            if self.parent:
                self.parent.remove_widget(self)

        anim.bind(on_complete=on_finish)
        anim.start(self)

    def on_bgm_slider_change(self, value):
        """Handle real-time BGM volume slider adjustments."""
        self.bgm_volume_percent = max(0, min(100, int(value)))
        vol_float = self.bgm_volume_percent / 100.0

        # Update audio engine
        AudioManager.get_instance().set_bgm_volume(vol_float)

        # Persist in JsonStore
        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            app.player_data.set_bgm_volume(vol_float)

    def on_sfx_slider_change(self, value):
        """Handle real-time SFX volume slider adjustments."""
        self.sfx_volume_percent = max(0, min(100, int(value)))
        vol_float = self.sfx_volume_percent / 100.0

        # Update audio engine
        AudioManager.get_instance().set_sfx_volume(vol_float)

        # Persist in JsonStore
        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            app.player_data.set_sfx_volume(vol_float)

    def on_sfx_slider_touch_up(self, slider: Slider, touch):
        """Play a preview click when the user finishes adjusting the SFX slider."""
        if slider.collide_point(*touch.pos):
            play_click()

    def on_touch_down(self, touch):
        """Consume touches within dialog; tapping backdrop outside card closes dialog."""
        if not self.collide_point(*touch.pos):
            return False

        card = self.ids.get("card_container")
        if card and not card.collide_point(*touch.pos):
            # Clicked outside the modal card -> close dialog
            self.close()
            return True

        return super().on_touch_down(touch)
