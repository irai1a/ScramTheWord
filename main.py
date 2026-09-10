import os
import sys
import time
import traceback
from kivy.base import ExceptionHandler, ExceptionManager
from kivy.clock import Clock
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
from loading_screen import LoadingScreen
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
        try:
            if not self.collide_point(*touch.pos):
                if self.parent and hasattr(self.parent, "to_widget"):
                    p_pos = self.parent.to_widget(*touch.pos)
                    if not self.collide_point(*p_pos):
                        return False
                else:
                    return False
            if self.disabled or self.is_disabled:
                return True
            if getattr(touch, "is_mouse_scrolling", False):
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
        except Exception as e:
            print(f"[WoodPlankButton] touch_down error: {e}")
            return False

    def on_touch_up(self, touch):
        try:
            if touch.grab_current is not self:
                return False
            touch.ungrab(self)
            self.last_touch = touch
            self.state = "normal"

            # Check collision in both local and window coordinate frames
            is_hit = self.collide_point(*touch.pos)
            if not is_hit and self.parent and hasattr(self.parent, "to_widget"):
                p_pos = self.parent.to_widget(*touch.pos)
                is_hit = self.collide_point(*p_pos)

            if is_hit:
                self.dispatch("on_release")
            return True
        except Exception as e:
            print(f"[WoodPlankButton] touch_up error: {e}")
            return False


from kivy.factory import Factory
Factory.register("WoodPlankButton", cls=WoodPlankButton)


class CrashScreen(MDScreen):
    """On-screen diagnostic crash recovery screen."""

    error_summary = StringProperty("An unexpected issue was caught.")
    error_details = StringProperty("Details will appear here.")
    log_path_display = StringProperty("")

    def show_error(self, summary: str, details: str):
        self.error_summary = str(summary)
        self.error_details = str(details)
        try:
            app = MDApp.get_running_app()
            if app and hasattr(app, "user_data_dir"):
                self.log_path_display = os.path.join(app.user_data_dir, "crash_log.txt")
            else:
                self.log_path_display = "crash_log.txt"
        except Exception:
            self.log_path_display = "crash_log.txt"

    def return_to_main_menu(self):
        try:
            app = MDApp.get_running_app()
            if hasattr(app, "switch_screen"):
                app.switch_screen("main_menu")
            elif app.root:
                app.root.current = "main_menu"
        except Exception as e:
            print(f"[CrashScreen] Return error: {e}")


Factory.register("CrashScreen", cls=CrashScreen)


class GlobalCrashHandler(ExceptionHandler):
    """Catches all unhandled exceptions so the app NEVER crashes out to the Android home screen."""

    def handle_exception(self, inst):
        formatted = traceback.format_exc()
        print(f"[WhackAWordHamApp CRASH INTERCEPTED]:\n{formatted}")

        # 1. Write crash details to disk
        try:
            app = MDApp.get_running_app()
            log_dir = app.user_data_dir if (app and hasattr(app, "user_data_dir")) else "."
            os.makedirs(log_dir, exist_ok=True)
            log_file = os.path.join(log_dir, "crash_log.txt")
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"\n--- ERROR AT {time.ctime()} ---\n{formatted}\n")
        except Exception as e:
            print(f"[GlobalCrashHandler] File write error: {e}")

        # 2. Transition safely to on-screen diagnostic recovery
        try:
            app = MDApp.get_running_app()
            if app and app.root:
                if hasattr(app.root, "has_screen") and app.root.has_screen("crash_screen"):
                    crash_screen = app.root.get_screen("crash_screen")
                    if crash_screen:
                        crash_screen.show_error(str(inst), formatted)
                    app.root.current = "crash_screen"
        except Exception as e:
            print(f"[GlobalCrashHandler] Screen switch error: {e}")

        return ExceptionManager.PASS


ExceptionManager.add_handler(GlobalCrashHandler())



class MainMenuScreen(MDScreen):
    """Main menu screen displaying game title, player stats, and primary navigation buttons."""

    current_stage_display = NumericProperty(1)
    coins_display = NumericProperty(0)

    def on_enter(self, *args):
        """Refresh player stats from local store whenever player returns to Main Menu."""
        super().on_enter(*args)
        try:
            play_bgm("main")
        except Exception:
            pass

        app = MDApp.get_running_app()
        if hasattr(app, "player_data") and app.player_data is not None:
            try:
                app.player_data.load()
                self.current_stage_display = app.player_data.get_current_stage()
                self.coins_display = app.player_data.get_coins()
                app.player_data.bind(
                    current_stage=self._on_stage_update,
                    coins=self._on_coins_update,
                )
            except Exception as e:
                print(f"[MainMenuScreen] Warning: player_data sync error: {e}")

    def _on_stage_update(self, instance, value):
        self.current_stage_display = int(value)

    def _on_coins_update(self, instance, value):
        self.coins_display = int(value)

    def open_settings(self):
        """Open the Audio Settings dialog modal."""
        try:
            from settings_dialog import SettingsDialog
            if not hasattr(self, "_settings_dialog") or not self._settings_dialog:
                self._settings_dialog = SettingsDialog()
            self._settings_dialog.open(self)
        except Exception as e:
            print(f"[MainMenuScreen] Warning: open_settings error: {e}")


class MultiplayerScreen(MDScreen):
    """Multiplayer ranked screen displaying upcoming competitive modes."""

    def on_enter(self, *args):
        super().on_enter(*args)
        try:
            play_bgm("main")
        except Exception:
            pass

    def on_back_to_menu(self):
        try:
            play_click()
            app = MDApp.get_running_app()
            if hasattr(app, "switch_screen"):
                app.switch_screen("main_menu")
            else:
                app.root.current = "main_menu"
        except Exception as e:
            print(f"[MultiplayerScreen] Warning: back_to_menu error: {e}")


class WhackAWordHamApp(MDApp):
    """Main application class for Whack-A-Word_Ham game."""

    title = "Whack-A-Word_Ham"
    player_data = ObjectProperty(None)
    _settings_dialog = None

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Initialize the local persistent player data store in the writable user_data_dir
        try:
            data_dir = self.user_data_dir
            os.makedirs(data_dir, exist_ok=True)
            data_file = os.path.join(data_dir, "player_data.json")
            bundled_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "player_data.json")
            if not os.path.exists(data_file) and os.path.exists(bundled_file):
                import shutil
                shutil.copy2(bundled_file, data_file)
            self.player_data = PlayerDataManager(filename=data_file)
        except Exception as e:
            print(f"[WhackAWordHamApp] Warning: Could not initialize user_data_dir store ({e}), falling back.")
            self.player_data = PlayerDataManager()

    def on_start(self):
        """Start background music and initialize AdMob on app launch."""
        super().on_start()
        play_bgm("main")
        try:
            from ad_manager import init_ads
            init_ads()
        except Exception as e:
            print(f"[WhackAWordHamApp] AdMob initialization error: {e}")

    def build(self):
        # Configure a modern, vibrant theme
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Indigo"

        # Only restrict window dimensions when running on Desktop preview (never on mobile devices)
        from kivy.utils import platform
        if platform not in ("android", "ios"):
            Window.size = (440, 780)
            Window.minimum_width, Window.minimum_height = (360, 600)

        # Load the KV layout file
        return Builder.load_file("game.kv")

    def switch_screen(self, screen_name: str, *args):
        """Safely transition to target screen on the next frame to prevent touch event collisions."""
        if getattr(self, "_is_switching_screen", False):
            return
        if self.root and getattr(self.root, "current", None) == screen_name:
            return
        self._is_switching_screen = True

        def _do_switch(dt):
            try:
                if self.root:
                    if hasattr(self.root, "has_screen") and self.root.has_screen(screen_name):
                        self.root.current = screen_name
                    elif hasattr(self.root, "current"):
                        self.root.current = screen_name
            except Exception as e:
                print(f"[WhackAWordHamApp] Warning: error switching to {screen_name}: {e}")
            finally:
                self._is_switching_screen = False

        Clock.schedule_once(_do_switch, 0.04)

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
