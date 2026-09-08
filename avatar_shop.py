"""Avatar Shop screen logic for Scram The Word.

Features:
- Avatar preview area at the top using Image widgets (base avatar character and dynamic accessory overlay)
- Reactive coin balance counter updating in real time
- Accessories grid layout utilizing MDScrollView and MDGridLayout
- Item cards with accessory preview, name, price, and dynamic action buttons:
  - 'Buy (X Coins)' when unowned (deducts coins & adds to owned_accessories via JsonStore)
  - 'Equip' when owned (equips accessory and updates avatar preview overlay in real time)
  - 'Equipped' when currently equipped (allows unequipping)
"""

import os
from typing import Any, Dict, List, Optional

from kivy.animation import Animation
from kivy.clock import Clock
from kivy.metrics import dp
# pyrefly: ignore [missing-import]
from kivy.properties import ColorProperty, NumericProperty, StringProperty
from kivymd.app import MDApp
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.button import MDButton, MDButtonIcon, MDButtonText
from kivymd.uix.card import MDCard
from kivy.uix.image import Image
from kivymd.uix.fitimage import FitImage
from kivymd.uix.label import MDIcon, MDLabel
from kivymd.uix.screen import MDScreen
from audio_manager import play_bgm, play_click



# Catalog of available accessories
ACCESSORIES: List[Dict[str, Any]] = [
    {
        "id": "cap",
        "name": "Cap",
        "price": 30,
        "icon": "hat-fedora",
        "overlay": "assets/cap.png",
        "description": "Trendy red snapback cap",
    },
    {
        "id": "glasses",
        "name": "Glasses",
        "price": 50,
        "icon": "sunglasses",
        "overlay": "assets/glasses.png",
        "description": "Cool golden pixel shades",
    },
    {
        "id": "headphones",
        "name": "Headphones",
        "price": 80,
        "icon": "headphones",
        "overlay": "assets/headphones.png",
        "description": "Neon cyan gaming headset",
    },
    {
        "id": "ninja_mask",
        "name": "Ninja Mask",
        "price": 100,
        "icon": "face-mask",
        "overlay": "assets/ninja_mask.png",
        "description": "Stealth rogue face mask",
    },
    {
        "id": "crown",
        "name": "Crown",
        "price": 150,
        "icon": "crown",
        "overlay": "assets/crown.png",
        "description": "Royal golden jeweled crown",
    },
    {
        "id": "wizard_hat",
        "name": "Wizard Hat",
        "price": 200,
        "icon": "creation",
        "overlay": "assets/wizard_hat.png",
        "description": "Enchanted celestial hat",
    },
]


class AccessoryCard(MDCard):
    """Card widget representing an accessory in the shop grid."""

    def __init__(
        self,
        item: Dict[str, Any],
        is_owned: bool,
        is_equipped: bool,
        on_action_callback,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.item = item
        self.is_owned = is_owned
        self.is_equipped = is_equipped
        self.on_action_callback = on_action_callback

        self.style = "elevated"
        self.theme_bg_color = "Custom"
        self.md_bg_color = [0.22, 0.15, 0.10, 0.92]
        self.line_color = [0.46, 0.32, 0.18, 0.85]
        self.size_hint_y = None
        self.height = dp(212)
        self.radius = [dp(18), dp(18), dp(18), dp(18)]
        self.padding = [dp(12), dp(12), dp(12), dp(12)]
        self.pos_hint = {"center_x": 0.5}

        # Build card content
        container = MDBoxLayout(
            orientation="vertical",
            spacing=dp(8),
            pos_hint={"center_x": 0.5, "center_y": 0.5},
        )

        # 1. Accessory Preview thumbnail container (Carved wood alcove)
        thumb_card = MDCard(
            style="filled",
            theme_bg_color="Custom",
            md_bg_color=[0.16, 0.11, 0.07, 0.92],
            line_color=[0.42, 0.28, 0.16, 0.70],
            size_hint=(None, None),
            size=(dp(64), dp(64)),
            radius=[dp(16), dp(16), dp(16), dp(16)],
            pos_hint={"center_x": 0.5},
            padding=[dp(4), dp(4), dp(4), dp(4)],
        )

        # Thumbnail Icon Widget
        thumb_widget = MDIcon(
            icon=item.get("icon", "tshirt-crew"),
            font_size="34sp",
            theme_icon_color="Custom",
            icon_color=[1.0, 0.78, 0.2, 1.0] if is_equipped else [0.75, 0.84, 1.0, 1.0],
            pos_hint={"center_x": 0.5, "center_y": 0.5},
        )
        thumb_card.add_widget(thumb_widget)
        container.add_widget(thumb_card)

        # 2. Item Name
        name_label = MDLabel(
            text=item.get("name", "Accessory"),
            bold=True,
            halign="center",
            font_style="Title",
            role="small",
            theme_text_color="Custom",
            text_color=[1.0, 0.94, 0.84, 1.0],
            adaptive_height=True,
            pos_hint={"center_x": 0.5},
        )
        container.add_widget(name_label)

        # 3. Price or Status indicator
        status_box = MDBoxLayout(
            adaptive_size=True,
            spacing=dp(4),
            pos_hint={"center_x": 0.5},
        )
        if not is_owned:
            coin_icon = MDIcon(
                icon="circle-multiple",
                font_size="16sp",
                theme_icon_color="Custom",
                icon_color=[1.0, 0.82, 0.15, 1.0],
                pos_hint={"center_y": 0.5},
            )
            price_label = MDLabel(
                text=f"{item.get('price', 0)} Coins",
                font_style="Label",
                role="medium",
                bold=True,
                theme_text_color="Custom",
                text_color=[1.0, 0.88, 0.35, 1.0],
                adaptive_size=True,
                pos_hint={"center_y": 0.5},
            )
            status_box.add_widget(coin_icon)
            status_box.add_widget(price_label)
        elif is_equipped:
            equipped_label = MDLabel(
                text="Currently Equipped ★",
                font_style="Label",
                role="small",
                bold=True,
                adaptive_size=True,
                theme_text_color="Custom",
                text_color=[0.35, 0.90, 0.45, 1.0],
                pos_hint={"center_y": 0.5},
            )
            status_box.add_widget(equipped_label)
        else:
            owned_label = MDLabel(
                text="Owned",
                font_style="Label",
                role="small",
                adaptive_size=True,
                theme_text_color="Custom",
                text_color=[0.82, 0.78, 0.70, 1.0],
                pos_hint={"center_y": 0.5},
            )
            status_box.add_widget(owned_label)
        container.add_widget(status_box)

        # 4. Action Button (Wood & Forest Themed)
        action_btn = MDButton(
            size_hint_x=1,
            height=dp(40),
            pos_hint={"center_x": 0.5},
            on_release=lambda x: self.on_action_callback(self.item),
        )

        if not is_owned:
            action_btn.style = "filled"
            action_btn.theme_bg_color = "Custom"
            action_btn.md_bg_color = [0.68, 0.42, 0.14, 1.0]
            action_btn.add_widget(MDButtonText(text=f"Buy ({item.get('price', 0)} C)", bold=True, theme_text_color="Custom", text_color=[1.0, 0.96, 0.90, 1.0]))
        elif is_equipped:
            action_btn.style = "filled"
            action_btn.theme_bg_color = "Custom"
            action_btn.md_bg_color = [0.18, 0.58, 0.28, 1.0]
            action_btn.add_widget(MDButtonText(text="Equipped", bold=True, theme_text_color="Custom", text_color=[1.0, 1.0, 1.0, 1.0]))
        else:
            action_btn.style = "filled"
            action_btn.theme_bg_color = "Custom"
            action_btn.md_bg_color = [0.38, 0.26, 0.16, 1.0]
            action_btn.add_widget(MDButtonText(text="Equip", bold=True, theme_text_color="Custom", text_color=[1.0, 0.92, 0.80, 1.0]))

        container.add_widget(action_btn)
        self.add_widget(container)


class AvatarShopScreen(MDScreen):
    """Avatar Shop screen with base avatar preview and interactive accessory shop grid."""

    equipped_overlay_source = StringProperty("assets/empty.png")
    equipped_item_name = StringProperty("None")
    shop_banner_text = StringProperty("Select an accessory to customize your avatar character.")
    shop_banner_bg = ColorProperty([0.22, 0.15, 0.09, 0.92])
    shop_banner_text_color = ColorProperty([0.96, 0.92, 0.84, 1.0])
    frame1_opacity = NumericProperty(1.0)
    frame2_opacity = NumericProperty(0.0)
    _breathing_clock_event = None

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.accessories = ACCESSORIES

    def on_enter(self, *args):
        """Called automatically when navigating into AvatarShopScreen."""
        super().on_enter(*args)
        try:
            play_bgm("wardrobe")
        except Exception:
            pass

        try:
            self.update_avatar_preview()
            self.render_shop_items()
            self.start_idle_animation()
        except Exception as e:
            print(f"[AvatarShopScreen] Warning: on_enter error: {e}")

    def on_leave(self, *args):
        """Called automatically when navigating away from AvatarShopScreen."""
        self.stop_idle_animation()

    def cut_to_frame1(self, dt=0):
        """Clean instant cut to Frame 1 (alert / inhale). Zero opacity crossfade."""
        self.frame1_opacity = 1.0
        self.frame2_opacity = 0.0

    def cut_to_frame2(self, dt=0):
        """Clean instant cut to Frame 2 (happy smile / exhale). Zero opacity crossfade."""
        self.frame1_opacity = 0.0
        self.frame2_opacity = 1.0

    def start_idle_animation(self):
        """Start clean, discrete frame-by-frame breathing idle animation without any in-between ghosting."""
        container = self.ids.get("hamster_idle_container")
        if not container:
            return

        Animation.stop_all(container)
        self.stop_idle_animation()

        # Anchor container firmly on the floor (no floating)
        container.pos_hint = {"center_x": 0.5, "center_y": 0.5}
        container.size_hint = (1.0, 1.0)

        # Discrete frame switching sequence:
        # Phase 1: Inhale (Frame 1 alert, open eyes) held for 1.8s
        # Phase 2: Exhale (Frame 2 relaxed, happy squinting smile) held for 1.2s
        # Instant cut (0s opacity transition) so there is never any double-exposure ghosting!
        self.cut_to_frame1()

        def switch_to_exhale(dt):
            self.cut_to_frame2()
            self._breathing_clock_event = Clock.schedule_once(switch_to_inhale, 1.2)

        def switch_to_inhale(dt):
            self.cut_to_frame1()
            self._breathing_clock_event = Clock.schedule_once(switch_to_exhale, 1.8)

        self._breathing_clock_event = Clock.schedule_once(switch_to_exhale, 1.8)

    def stop_idle_animation(self):
        """Cleanly cancel the breathing animation and reset to resting frame."""
        if self._breathing_clock_event:
            self._breathing_clock_event.cancel()
            self._breathing_clock_event = None
        container = self.ids.get("hamster_idle_container")
        if container:
            Animation.stop_all(container)
            container.pos_hint = {"center_x": 0.5, "center_y": 0.5}
            container.size_hint = (1.0, 1.0)
        self.frame1_opacity = 1.0
        self.frame2_opacity = 0.0

    def play_equip_hop(self):
        """Trigger a delightful celebratory bounce whenever the player buys or equips an accessory."""
        container = self.ids.get("hamster_idle_container")
        if not container:
            return
        self.stop_idle_animation()

        # Show happy smiling face cleanly during celebratory hop
        self.frame1_opacity = 0.0
        self.frame2_opacity = 1.0

        # Energetic happy hop: pre-jump squash -> launch -> landing squash -> return to breathing idle
        hop = (
            Animation(
                pos_hint={"center_x": 0.5, "center_y": 0.44},
                size_hint=(1.08, 0.90),
                duration=0.10,
                t="out_quad",
            )
            + Animation(
                pos_hint={"center_x": 0.5, "center_y": 0.65},
                size_hint=(0.92, 1.10),
                duration=0.18,
                t="out_quad",
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
        hop.bind(on_complete=lambda *args: self.start_idle_animation())
        hop.start(container)

    def update_avatar_preview(self):
        """Update the base avatar character overlay according to equipped_accessory in JsonStore."""
        app = MDApp.get_running_app()
        equipped_id = None
        if hasattr(app, "player_data") and app.player_data is not None:
            equipped_id = app.player_data.get_equipped_accessory()

        # Match equipped accessory ID to overlay asset
        found = False
        if equipped_id:
            for item in self.accessories:
                if item["id"] == equipped_id:
                    self.equipped_overlay_source = item["overlay"]
                    self.equipped_item_name = item["name"]
                    found = True
                    break

        if not found:
            self.equipped_overlay_source = "assets/empty.png"
            self.equipped_item_name = "None"

    def render_shop_items(self):
        """Populate the MDGridLayout with AccessoryCard widgets."""
        grid = self.ids.get("shop_grid")
        if not grid:
            return

        grid.clear_widgets()

        app = MDApp.get_running_app()
        owned_ids = []
        equipped_id = None
        if hasattr(app, "player_data") and app.player_data is not None:
            owned_ids = app.player_data.get_owned_accessories()
            equipped_id = app.player_data.get_equipped_accessory()

        for item in self.accessories:
            is_owned = item["id"] in owned_ids
            is_equipped = (item["id"] == equipped_id)
            card = AccessoryCard(
                item=item,
                is_owned=is_owned,
                is_equipped=is_equipped,
                on_action_callback=self.on_item_action,
            )
            grid.add_widget(card)

    def on_item_action(self, item: Dict[str, Any]):
        """Handler for card button clicks (Buy, Equip, or Unequip)."""
        play_click()
        app = MDApp.get_running_app()
        if not hasattr(app, "player_data") or app.player_data is None:
            return

        item_id = item["id"]
        is_owned = app.player_data.has_accessory(item_id)
        is_equipped = (app.player_data.get_equipped_accessory() == item_id)

        if not is_owned:
            # Attempt purchase
            price = item.get("price", 0)
            current_coins = app.player_data.get_coins()

            if current_coins >= price:
                app.player_data.spend_coins(price)
                app.player_data.add_accessory(item_id)
                self.show_banner(
                    f"🎉 Successfully purchased {item['name']} for {price} coins! Tap Equip to wear it.",
                    banner_type="success",
                )
                self.play_equip_hop()
                self.render_shop_items()
            else:
                needed = price - current_coins
                self.show_banner(
                    f"⚠️ Not enough coins for {item['name']}! You need {needed} more coins.",
                    banner_type="warning",
                )
        elif is_equipped:
            # Unequip currently worn accessory
            app.player_data.unequip_accessory()
            self.show_banner(f"Unequipped {item['name']}.", banner_type="neutral")
            self.update_avatar_preview()
            self.play_equip_hop()
            self.render_shop_items()
        else:
            # Equip accessory
            app.player_data.equip_accessory(item_id)
            self.show_banner(f"✨ Equipped {item['name']} on your avatar!", banner_type="success")
            self.update_avatar_preview()
            self.play_equip_hop()
            self.render_shop_items()


    def show_banner(self, message: str, banner_type: str = "neutral"):
        """Display feedback banner with appropriate color scheme."""
        self.shop_banner_text = message
        if banner_type == "success":
            self.shop_banner_bg = [0.12, 0.62, 0.32, 1.0]
            self.shop_banner_text_color = [1.0, 1.0, 1.0, 1.0]
        elif banner_type == "warning":
            self.shop_banner_bg = [0.85, 0.55, 0.12, 1.0]
            self.shop_banner_text_color = [1.0, 1.0, 1.0, 1.0]
        elif banner_type == "error":
            self.shop_banner_bg = [0.82, 0.22, 0.22, 1.0]
            self.shop_banner_text_color = [1.0, 1.0, 1.0, 1.0]
        else:
            self.shop_banner_bg = [0.22, 0.15, 0.09, 0.92]
            self.shop_banner_text_color = [0.96, 0.92, 0.84, 1.0]

    def on_back_to_menu(self):
        """Play click sound and return player to MainMenuScreen."""
        try:
            play_click()
            app = MDApp.get_running_app()
            app.root.current = "main_menu"
        except Exception as e:
            print(f"[AvatarShopScreen] Warning: on_back_to_menu error: {e}")
