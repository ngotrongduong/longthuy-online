"""Naming and theme rules of the low-poly library, shared by resort.py and split_sets.py.

The theme words are the RULES of harvest.js (one list for the downloader and the tidy-up tools).
"""
import re
from pathlib import Path

JS = (Path(__file__).resolve().parent / "harvest.js").read_text(encoding="utf-8")
RULES = [(th, sb, re.compile(rx)) for th, sb, rx in re.findall(r"\['(\w+)', '(\w+)', /(.+)/\],", JS)]
STOP = set(re.findall(r"'([^']*)'", re.search(r"const STOP = new Set\(\[(.*?)\]\)", JS, re.S).group(1)))
SETRE = re.compile(re.search(r"const SETRE = /(.+)/;", JS).group(1))
WEAK = {("Characters", "Characters"), ("Monsters", "Other_Monsters")}
LIVING = {"Monsters", "Animals", "Characters"}
DESCRIBING = {"stone", "stones", "rock", "rocks", "gold", "crystal", "crystals", "log", "vine", "pot", "giant", "boss",
              "pet", "toy", "toys", "king", "queen"}
CUT = re.compile(r"\b(holding|wielding|carrying|wearing|riding|made|using|inside|under|near|sitting|standing|on|in|with)\b.*")
IP = re.compile(r"\b(pokemon|pok[eé]mon|pikachu|charizard|eevee|vulpix|bulbasaur|squirtle|jigglypuff|minecraft|creeper|"
                r"pepe|mario|luigi|bowser|yoshi|sonic the|sonic hedgehog|zelda|triforce|hylian|kirby|pacman|pac man|disney|mickey|minnie|"
                r"marvel|spiderman|spider man|batman|superman|iron man|ironman|hulk|thor|stormbreaker|mjolnir|"
                r"captain america|deadpool|groot|doom guy|doomguy|skeletor|starcraft|roggenrola|naruto|goku|vegeta|dragon ball|luffy|harry potter|hogwarts|"
                r"filch|dumbledore|star wars|darth|vader|yoda|mandalorian|lightsaber|stormtrooper|jedi|master chief|"
                r"fortnite|among us|amogus|shrek|spongebob|hello kitty|sanrio|totoro|ghibli|genshin|"
                r"keyblade|final fantasy|sephiroth|gundam|transformers|optimus|godzilla|toothless|elsa|olaf|"
                r"buzz lightyear|lego|barbie|poppy playtime|huggy|fnaf|freddy|fazbear|springtrap|bendy|cuphead|"
                r"undertale|hollow knight|terraria|witcher|skyrim|elden ring|megaman|mega man|street fighter|"
                r"mortal kombat|overwatch|valorant|ghostface|pennywise|chucky|xenomorph|terminator|robocop|"
                r"ghostbusters|scooby|garfield|snoopy|smurf|peppa|bluey|paw patrol|labubu|skibidi|toji|gojo|"
                r"jujutsu|tanjiro|nezuko|demon slayer|sydney opera|animal crossing|lilo)\b")
LIMIT = 20000                                    # Roblox's limit for one mesh
MAX = {"Weapons": 10000, "Props": 10000}         # the library keeps small things lighter; others LIMIT


def make_name(raw, fallback):
    s = re.split(r"[,.;:\n(]", raw or "")[0]
    s = re.sub(r"[_\-]+", " ", s)
    s = re.sub(r"[^\w ]+", " ", s)
    words = [w for w in s.split() if re.fullmatch(r"[A-Za-z0-9]+", w) and w.lower() not in STOP][:5]
    n = "_".join(w[0].upper() + w[1:].lower() for w in words)
    return n if len(n) >= 3 else fallback


def classify(name):
    """((theme, sub, sure), places the name allows) from the last word a rule knows, or (None, set()).
    Describing words (stone, gold, giant...) lose to any other word; generic words (creature, warrior...) lose to
    a named creature, and when one ends the name the objects before it are only its parts."""
    text = CUT.sub("", name.replace("_", " ").lower()).strip()
    ms = [(m.end(), -i, th, sb, m.group(0)) for i, (th, sb, rx) in enumerate(RULES) for m in rx.finditer(text)]
    if any(m[4] not in DESCRIBING for m in ms):
        ms = [m for m in ms if m[4] not in DESCRIBING]
    if any(m[2] in LIVING and (m[2], m[3]) not in WEAK for m in ms):
        ms = [m for m in ms if (m[2], m[3]) not in WEAK]
    if ms and (max(ms)[2], max(ms)[3]) in WEAK:
        ms = [m for m in ms if m[2] in LIVING]
    if not ms:
        return None, set()
    _, _, th, sb, _ = max(ms)
    return (th, sb, (th, sb) not in WEAK), {(m[2], m[3]) for m in ms}
