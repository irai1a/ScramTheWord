import os
import sys
from kivy.core.window import Window
from kivy.lang import Builder
from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen
from kivymd.uix.screenmanager import MDScreenManager


# pyrefly: ignore [missing-import]
from kivy.properties import BooleanProperty, ListProperty, NumericProperty, ObjectProperty, StringProperty
from kivy.uix.behaviors import ButtonBehavior
from kivymd.uix.relativelayout import MDRelativeLayout
from player_data import PlayerDataManager
from stage_mode import StageModeScreen
from avatar_shop import AvatarShopScreen
from map_screen import MapScreen
from audio_manager import play_bgm, play_click


class WoodPlankButton(ButtonBehavior, MDRelativeLayout):
    """A tactile, wood-carved push button widget with embossed typography and state feedback."""

    normal_bg = StringProperty("assets/wood_btn_play_wide.png")
    pressed_bg = StringProperty("assets/wood_btn_play_wide_pressed.png")
    button_text = StringProperty("")
    button_icon = StringProperty("")
    text_color = ListProperty([1.0, 0.96, 0.88, 1.0])
    icon_color = ListProperty([0.98, 0.92, 0.75, 1.0])
    badge_visible = BooleanProperty(False)
    badge_text = StringProperty("")
    is_disabled = BooleanProperty(False)

    def on_touch_down(self, touch):
        if not self.collide_point(*touch.pos):
            return False
        if self.disabled or self.is_disabled:
            return True
        if touch.is_mouse_scrolling:
            return False
        if self in touch.ud:
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


from kivy.factory import Factory
Factory.register("WoodPlankButton", cls=WoodPlankButton)



class MainMenuScreen(MDScreen):
    """Main menu screen displaying game title, player stats, and primary navigation buttons."""

    current_stage_display = NumericProperty(1)
    coins_display = NumericProperty(0)

    def on_enter(self, *args):
        """Refresh player stats from local store whenever player returns to Main Menu."""
        super().on_enter(*args)
        play_bgm("main")
        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            app.player_data.load()
            self.current_stage_display = app.player_data.get_current_stage()
            self.coins_display = app.player_data.get_coins()
            app.player_data.bind(
                current_stage=self._on_stage_update,
                coins=self._on_coins_update,
            )

    def _on_stage_update(self, instance, value):
        self.current_stage_display = int(value)

    def _on_coins_update(self, instance, value):
        self.coins_display = int(value)

    def open_settings(self):
        """Open the Audio Settings dialog modal."""
        from settings_dialog import SettingsDialog
        if not hasattr(self, "_settings_dialog") or not self._settings_dialog:
            self._settings_dialog = SettingsDialog()
        self._settings_dialog.open(self)


class MultiplayerScreen(MDScreen):
    """Multiplayer ranked screen displaying upcoming competitive modes."""

    def on_enter(self, *args):
        super().on_enter(*args)
        play_bgm("main")

    def on_back_to_menu(self):
        play_click()
        app = MDApp.get_running_app()
        app.root.current = "main_menu"


class WhackAWordHamApp(MDApp):
    """Main application class for Whack-A-Word_Ham game."""

    title = "Whack-A-Word_Ham"
    player_data = ObjectProperty(None)
    _settings_dialog = None

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Initialize the local persistent player data store
        self.player_data = PlayerDataManager()

    def on_start(self):
        """Start background music as soon as the player launches the game."""
        super().on_start()
        play_bgm("main")

    def build(self):
        # Configure a modern, vibrant theme
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Indigo"

        # Set window dimensions suited for modern mobile/desktop preview
        Window.size = (440, 780)
        Window.minimum_width, Window.minimum_height = (360, 600)

        # Load the KV layout file
        return Builder.load_file("game.kv")

    def open_settings_dialog(self):
        """Open the global Audio Settings dialog modal."""
        from settings_dialog import SettingsDialog
        if not self._settings_dialog:
            self._settings_dialog = SettingsDialog()
        self._settings_dialog.open(self.root)


# Backwards compatibility alias
ScramTheWordApp = WhackAWordHamApp


if __name__ == "__main__":
    WhackAWordHamApp().run()
