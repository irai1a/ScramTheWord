"""LoadingScreen Module for Whack-A-Word_Ham.

Implements an authentic game loading/preloader screen that:
1. Displays an animated woodland progress bar and cute hamster avatar.
2. Pre-warms and pre-loads all app resources (player_data, audio buffers, 30 stage map nodes,
   words database, and avatar shop accessories) before the player can interact with any buttons.
3. Once 100% pre-loaded, cleanly transitions into MainMenuScreen.
"""

from kivy.animation import Animation
from kivy.clock import Clock
from kivy.factory import Factory
from kivy.metrics import dp
from kivy.properties import NumericProperty, StringProperty
from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen


class LoadingScreen(MDScreen):
    """Initial preloader screen that warms up all screens, data, and audio before entering main menu."""

    progress_value = NumericProperty(0.0)
    progress_percent_text = StringProperty("0%")
    status_message = StringProperty("Initializing woodland adventure...")

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._bobbing_anim = None

    def on_enter(self, *args):
        """Start pre-warming sequence upon entering the LoadingScreen."""
        super().on_enter(*args)
        print("[LoadingScreen] on_enter triggered! Starting pre-warming sequence...")
        self.progress_value = 0.05
        self.progress_percent_text = "5%"
        self.status_message = "Preparing woodland adventure..."

        # Start bobbing animation for avatar
        token = self.ids.get("hamster_loading_token")
        if token:
            anim = (
                Animation(pos_hint={"center_x": 0.5, "center_y": 0.54}, duration=0.55, t="in_out_sine")
                + Animation(pos_hint={"center_x": 0.5, "center_y": 0.48}, duration=0.55, t="in_out_sine")
            )
            anim.repeat = True
            self._bobbing_anim = anim
            anim.start(token)

        # Step 1: Initialize & sync player progress
        Clock.schedule_once(self._step_1_player_data, 0.15)

    def on_leave(self, *args):
        """Clean up animations upon leaving."""
        super().on_leave(*args)
        if self._bobbing_anim:
            token = self.ids.get("hamster_loading_token")
            if token:
                self._bobbing_anim.stop(token)

    def _step_1_player_data(self, dt):
        print("[LoadingScreen] Step 1 running...")
        try:
            app = MDApp.get_running_app()
            if hasattr(app, "player_data") and app.player_data is not None:
                app.player_data.load()
        except Exception as e:
            print(f"[LoadingScreen] Step 1 notice: {e}")

        self.progress_value = 0.28
        self.progress_percent_text = "28%"
        self.status_message = "Checking acorns & player progress..."
        Clock.schedule_once(self._step_2_audio, 0.20)

    def _step_2_audio(self, dt):
        print("[LoadingScreen] Step 2 running...")
        try:
            from audio_manager import AudioManager, play_bgm
            am = AudioManager.get_instance()
            # Pre-start BGM
            play_bgm("main")
        except Exception as e:
            print(f"[LoadingScreen] Step 2 notice: {e}")

        self.progress_value = 0.52
        self.progress_percent_text = "52%"
        self.status_message = "Tuning forest melodies & sound effects..."
        Clock.schedule_once(self._step_3_map, 0.20)

    def _step_3_map(self, dt):
        print("[LoadingScreen] Step 3 running...")
        try:
            app = MDApp.get_running_app()
            if app and app.root:
                map_screen = app.root.get_screen("map_screen")
                if map_screen:
                    # Pre-build all 30 nodes so map screen never lags or crashes when opened
                    map_screen.build_or_update_map()
        except Exception as e:
            print(f"[LoadingScreen] Step 3 notice: {e}")

        self.progress_value = 0.76
        self.progress_percent_text = "76%"
        self.status_message = "Assembling 30 progression map stages..."
        Clock.schedule_once(self._step_4_wardrobe_and_words, 0.20)

    def _step_4_wardrobe_and_words(self, dt):
        print("[LoadingScreen] Step 4 running...")
        try:
            app = MDApp.get_running_app()
            if app and app.root:
                # Pre-warm Hamster Wardrobe items
                shop_screen = app.root.get_screen("avatar_shop")
                if shop_screen:
                    shop_screen.render_shop_items()
                    shop_screen.update_avatar_preview()

                # Pre-warm Stage Mode words database
                stage_screen = app.root.get_screen("stage_mode")
                if stage_screen:
                    current_st = 1
                    if hasattr(app, "player_data") and app.player_data:
                        current_st = app.player_data.get_current_stage()
                    stage_screen.load_stage(current_st)
        except Exception as e:
            print(f"[LoadingScreen] Step 4 notice: {e}")

        self.progress_value = 1.0
        self.progress_percent_text = "100%"
        self.status_message = "Woodland adventure ready!"
        Clock.schedule_once(self._step_5_finish, 0.25)

    def _step_5_finish(self, dt):
        print("[LoadingScreen] Step 5 running! Switching to main_menu...")
        try:
            app = MDApp.get_running_app()
            if hasattr(app, "switch_screen"):
                app.switch_screen("main_menu")
            else:
                app.root.current = "main_menu"
        except Exception as e:
            print(f"[LoadingScreen] Step 5 notice: {e}")


Factory.register("LoadingScreen", cls=LoadingScreen)
