"""Whack-A-Word-Ham: Procedural Word Generation Module.

Generates dynamic stage content for Whack-A-Word-Ham based on stage number:
- Difficulty scales with stage: word_length = min(3 + (stage_number // 10), 10)
- Deterministic seeding: random.seed(stage_number) ensures cross-device consistency
- Coin rewards scale dynamically: reward = 10 + (stage_number // 5)
- Dynamic time limits scale with word length: time_limit = 30 + (word_length * 5)
- Robust infinite generation: supports infinite stages without running out of content
"""

import json
import os
import random
from typing import Any, Dict, List, Optional

# Path to the primary words database categorized by length
DEFAULT_WORDS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "words.json")

# Fallback words database in case words.json is ever missing or inaccessible
FALLBACK_WORDS: Dict[str, List[Dict[str, Any]]] = {
    "3": [
        {
            "word": "HAM",
            "description": "A lovable energetic hamster full of bouncy charm.",
            "hints": [
                "A lovable energetic hamster full of bouncy charm.",
                "Short for hamster or a savory cured delicacy.",
                "Contains 3 letters: H, A, M.",
                "Ends with the letter 'M'.",
                "Rhymes with 'JAM' and 'RAM'."
            ]
        },
        {
            "word": "CAT",
            "description": "A curious feline hunter that purrs in the warm sun.",
            "hints": [
                "A curious feline hunter that purrs in the warm sun.",
                "A beloved household pet known for agile jumps.",
                "Has 3 letters and retractile claws.",
                "Ends with the letter 'T'.",
                "Rhymes with 'BAT' and 'HAT'."
            ]
        },
        {
            "word": "OAK",
            "description": "A mighty enduring tree that sprouts from a humble acorn.",
            "hints": [
                "A mighty enduring tree that sprouts from a humble acorn.",
                "A hardwood tree producing sturdy timber and leaves.",
                "Contains 3 letters: O, A, K.",
                "Ends with the letter 'K'.",
                "Starts with the vowel 'O'."
            ]
        }
    ],
    "4": [
        {
            "word": "GAME",
            "description": "A playful contest of wits and strategy.",
            "hints": [
                "A playful contest of wits and strategy.",
                "Played for amusement, competition, or recreation.",
                "Involves rules, objectives, and winning.",
                "Ends with the letter 'E'.",
                "Rhymes with 'FAME' and 'NAME'."
            ]
        },
        {
            "word": "PINE",
            "description": "An evergreen tree with fragrant needles and woody cones.",
            "hints": [
                "An evergreen tree with fragrant needles and woody cones.",
                "Stands tall in mountain forests throughout winter.",
                "Contains 4 letters: P, I, N, E.",
                "Ends with the letter 'E'.",
                "Rhymes with 'FINE' and 'LINE'."
            ]
        }
    ],
    "5": [
        {
            "word": "ACORN",
            "description": "A smooth oval nut dropped by majestic oak trees.",
            "hints": [
                "A smooth oval nut dropped by majestic oak trees.",
                "Prized food gathered by busy hamsters and squirrels.",
                "Grows inside a tough woody cupule.",
                "Ends with the letter 'N'.",
                "Starts with the vowel 'A'."
            ]
        },
        {
            "word": "GROVE",
            "description": "A serene cluster of trees standing together in a meadow.",
            "hints": [
                "A serene cluster of trees standing together in a meadow.",
                "A small sheltered woodland haven.",
                "Contains 5 letters: G, R, O, V, E.",
                "Ends with the letter 'E'.",
                "Rhymes with 'COVE' and 'DROVE'."
            ]
        }
    ],
    "6": [
        {
            "word": "FOREST",
            "description": "A vast dense expanse of towering trees and wild critters.",
            "hints": [
                "A vast dense expanse of towering trees and wild critters.",
                "Home to streams, moss, deer, and hamsters.",
                "Features a high leafy green canopy.",
                "Ends with the letter 'T'.",
                "Starts with the letter 'F'."
            ]
        },
        {
            "word": "TIMBER",
            "description": "Sturdy wooden logs prepared for carpentry and warmth.",
            "hints": [
                "Sturdy wooden logs prepared for carpentry and warmth.",
                "Harvested from trees and used to build cabins.",
                "Contains 6 letters: T, I, M, B, E, R.",
                "Ends with the letter 'R'.",
                "Starts with the letter 'T'."
            ]
        }
    ],
    "7": [
        {
            "word": "HAMSTER",
            "description": "A lovable round rodent with capacious cheek pouches.",
            "hints": [
                "A lovable round rodent with capacious cheek pouches.",
                "Whack-A-Word's heroic cheerleader and companion.",
                "Loves running on exercise wheels and hoarding seeds.",
                "Ends with the letter 'R'.",
                "Starts with the letter 'H'."
            ]
        }
    ],
    "8": [
        {
            "word": "CHESTNUT",
            "description": "A shiny brown edible nut enclosed in a prickly green burr.",
            "hints": [
                "A shiny brown edible nut enclosed in a prickly green burr.",
                "Traditionally roasted over an open hearth in winter.",
                "Contains 8 letters: C, H, E, S, T, N, U, T.",
                "Ends with the letter 'T'.",
                "Starts with the letter 'C'."
            ]
        }
    ],
    "9": [
        {
            "word": "SUNFLOWER",
            "description": "A towering golden blossom that turns to follow the sun.",
            "hints": [
                "A towering golden blossom that turns to follow the sun.",
                "Produces delicious black-striped seeds loved by hamsters.",
                "Features radiant yellow petals like solar rays.",
                "Ends with the letter 'R'.",
                "Starts with the letter 'S'."
            ]
        }
    ],
    "10": [
        {
            "word": "WILDERNESS",
            "description": "An uncultivated and majestic expanse of untamed nature.",
            "hints": [
                "An uncultivated and majestic expanse of untamed nature.",
                "Where wild animals, mountains, and old-growth trees flourish.",
                "Untouched by urban cityscapes and roads.",
                "Ends with the letter 'S'.",
                "Starts with the letter 'W'."
            ]
        }
    ]
}

# Module-level cache for the loaded word database
_CACHED_WORDS_DB: Optional[Dict[str, List[Any]]] = None
_CACHED_DB_PATH: Optional[str] = None


def load_words_dictionary(file_path: Optional[str] = None) -> Dict[str, List[Any]]:
    """Load and return English word dictionary categorized by length.

    Args:
        file_path: Optional path to words JSON file. Defaults to DEFAULT_WORDS_FILE.

    Returns:
        A dictionary mapping length strings ('3' to '10', '10+') to lists of word items.
    """
    global _CACHED_WORDS_DB, _CACHED_DB_PATH

    target_path = file_path or DEFAULT_WORDS_FILE
    if _CACHED_WORDS_DB is not None and _CACHED_DB_PATH == target_path:
        return _CACHED_WORDS_DB

    loaded_db: Dict[str, List[Any]] = {}

    if os.path.exists(target_path):
        try:
            with open(target_path, "r", encoding="utf-8") as f:
                loaded_db = json.load(f)
        except Exception as err:
            print(f"[WordGenerator] Warning: Failed to load '{target_path}': {err}")

    # Merge or fallback with embedded words
    normalized_db: Dict[str, List[Any]] = {}
    for length_key in ["3", "4", "5", "6", "7", "8", "9", "10", "10+"]:
        entries = loaded_db.get(length_key, [])
        if not entries and length_key in FALLBACK_WORDS:
            entries = FALLBACK_WORDS[length_key]
        normalized_db[length_key] = entries

    _CACHED_WORDS_DB = normalized_db
    _CACHED_DB_PATH = target_path
    return _CACHED_WORDS_DB


def scramble_letters(word: str) -> List[str]:
    """Scramble the characters of a word into a shuffled list.

    Guarantees the scrambled sequence is not identical to the original word
    when there are at least two distinct characters.

    Args:
        word: The target word string.

    Returns:
        A list of scrambled single-character strings.
    """
    chars = list(word.upper())
    if len(chars) <= 1:
        return chars

    scrambled = chars[:]
    # Shuffle using seeded random state
    random.shuffle(scrambled)

    # If shuffle accidentally produced the exact same word, swap two different letters
    if scrambled == chars and len(set(chars)) > 1:
        for i in range(len(scrambled) - 1):
            if scrambled[i] != scrambled[i + 1]:
                scrambled[i], scrambled[i + 1] = scrambled[i + 1], scrambled[i]
                break

    return scrambled


def generate_stage(stage_number: int, words_file: Optional[str] = None) -> Dict[str, Any]:
    """Procedurally generate complete stage configuration for Whack-A-Word-Ham.

    Difficulty Formula:
        word_length = min(3 + (stage_number // 10), 10)

    Consistency Guarantee:
        random.seed(stage_number) is called before word selection and shuffling,
        guaranteeing identical stage content across different devices and runs.

    Reward Formula:
        reward = 10 + (stage_number // 5)

    Time Limit Formula:
        time_limit = 30 + (word_length * 5)

    Args:
        stage_number: The current stage integer (supports 1 to infinite).
        words_file: Optional custom path to words.json dictionary.

    Returns:
        Dict containing:
            - 'scrambled_letters': List[str] of scrambled characters
            - 'original_word': str of the target word in uppercase
            - 'reward_coins': int coin reward calculated dynamically
            - 'time_limit': int time limit in seconds
            - 'stage_number': int current stage
            - 'word_length': int length of the target word
            - 'description': str descriptive clue
            - 'hints': List[str] list of progressive hints
    """
    # Normalize stage number to non-negative integer
    stage = max(1, int(stage_number))

    # 1. Calculate difficulty based on stage_number:
    # word_length = min(3 + (stage_number // 10), 10)
    word_length = min(3 + (stage // 10), 10)

    # 2. Set random.seed(stage_number) so stage content is consistent across devices:
    random.seed(stage)

    # 3. Calculate coin rewards dynamically:
    # reward = 10 + (stage_number // 5)
    reward_coins = 10 + (stage // 5)

    # 4. Calculate dynamic time limit (e.g. 45s for 3-letter, up to 80s for 10-letter):
    time_limit = 30 + (word_length * 5)

    # 5. Load dictionary and select word matching word_length
    db = load_words_dictionary(words_file)
    key = str(word_length)
    candidate_list = db.get(key, [])

    # If key not found or empty, search adjacent lengths or 10+
    if not candidate_list:
        if word_length >= 10 and db.get("10+"):
            candidate_list = db["10+"]
        else:
            # Fallback to any available list
            for alt_key in [str(word_length), "4", "3", "5", "6"]:
                if db.get(alt_key):
                    candidate_list = db[alt_key]
                    break

    # If still empty, use built-in fallback
    if not candidate_list:
        candidate_list = FALLBACK_WORDS.get(key, FALLBACK_WORDS["3"])

    # Pick word deterministically using the seeded random generator
    chosen_item = random.choice(candidate_list)

    # Parse word entry (supports both dict object and plain string format)
    if isinstance(chosen_item, dict):
        original_word = str(chosen_item.get("word", "HAM")).upper().strip()
        description = str(chosen_item.get("description", ""))
        hints_raw = chosen_item.get("hints", [])
    else:
        original_word = str(chosen_item).upper().strip()
        description = ""
        hints_raw = []

    # Ensure 5 progressive hints
    hints = [h for h in hints_raw if isinstance(h, str) and h.strip()]
    if not hints:
        if description:
            hints.append(description)
        else:
            hints.append(f"A {len(original_word)}-letter woodland word waiting to be unscrambled.")

    vowels = sorted(set(c for c in original_word if c in "AEIOUY"))
    vowels_desc = ", ".join(vowels) if vowels else "none"

    fallback_hints = [
        f"This word begins with the letter '{original_word[0]}'.",
        f"This word ends with the letter '{original_word[-1]}'.",
        f"The word has {len(original_word)} letters with vowels: {vowels_desc}.",
        f"Think of words related to nature starting with '{original_word[0]}'.",
    ]
    fb_idx = 0
    while len(hints) < 5 and fb_idx < len(fallback_hints):
        hints.append(fallback_hints[fb_idx])
        fb_idx += 1
    while len(hints) < 5:
        hints.append(f"Starts with '{original_word[0]}' and ends with '{original_word[-1]}'.")

    if not description:
        description = hints[0]

    # 6. Scramble the letters into a shuffled list
    scrambled_letters = scramble_letters(original_word)

    return {
        "scrambled_letters": scrambled_letters,
        "original_word": original_word,
        "reward_coins": reward_coins,
        "time_limit": time_limit,
        "stage_number": stage,
        "word_length": len(original_word),
        "description": description,
        "hints": hints[:5],
    }


if __name__ == "__main__":
    print("=" * 65)
    print("Whack-A-Word-Ham: Procedural Word Generation Module Demo")
    print("=" * 65)

    sample_stages = [1, 5, 9, 10, 19, 20, 30, 40, 50, 60, 70, 75, 100, 1000]
    for s in sample_stages:
        data = generate_stage(s)
        scrambled_str = "".join(data["scrambled_letters"])
        print(
            f"Stage {data['stage_number']:<4} | "
            f"Len: {data['word_length']:<2} | "
            f"Word: {data['original_word']:<12} | "
            f"Scrambled: {scrambled_str:<12} | "
            f"Coins: {data['reward_coins']:<3} | "
            f"Time: {data['time_limit']}s"
        )

    print("\n--- Cross-Device Consistency Check ---")
    run1 = [generate_stage(st)["original_word"] for st in [1, 10, 25, 50]]
    run2 = [generate_stage(st)["original_word"] for st in [1, 10, 25, 50]]
    print(f"Run 1: {run1}")
    print(f"Run 2: {run2}")
    assert run1 == run2, "Consistency check failed!"
    print("Cross-device deterministic check PASSED!")
    print("=" * 65)
