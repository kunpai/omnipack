"""Generate Cobblemon spawn pools for Ad Astra planets.

Writes kubejs/data/cobblemon/spawn_pool_world/omnipack_<planet>.json.
Edit PLANETS below, then run:  python3 tools/gen_space_spawns.py

Only species with spawn data in Cobblemon 1.5.2 are used (others have no
model yet). Data under kubejs/data needs a full game/server restart.
"""

import json
from pathlib import Path
from typing import Dict, List, Tuple

OUT_DIR = Path(__file__).resolve().parent.parent / "kubejs/data/cobblemon/spawn_pool_world"

# (species, bucket, level range, weight)
Spawn = Tuple[str, str, str, int]

PLANETS: Dict[str, Dict] = {
    "moon": {
        "biomes": ["ad_astra:lunar_wastelands"],
        "blocks": ["ad_astra:moon_sand", "ad_astra:moon_stone",
                   "ad_astra:moon_cobblestone", "ad_astra:moon_deepslate"],
        "spawns": [
            ("clefairy", "common", "15-30", 10), ("lunatone", "common", "20-40", 10),
            ("elgyem", "common", "15-30", 9), ("bronzor", "uncommon", "15-30", 6),
            ("solrock", "uncommon", "20-40", 6), ("minior", "uncommon", "20-40", 6),
            ("munna", "uncommon", "15-30", 5), ("beldum", "rare", "20-35", 3),
            ("clefable", "rare", "35-50", 2), ("beheeyem", "rare", "35-50", 2),
        ],
    },
    "mars": {  # red desert: rock / ground
        "biomes": ["ad_astra:martian_wastelands", "ad_astra:martian_canyon_creek",
                   "ad_astra:martian_polar_caps"],
        "blocks": ["ad_astra:mars_sand", "ad_astra:mars_stone",
                   "ad_astra:mars_cobblestone", "minecraft:snow_block"],
        "spawns": [
            ("geodude", "common", "20-35", 10), ("diglett", "common", "20-35", 10),
            ("sandshrew", "common", "20-35", 9), ("numel", "common", "20-35", 8),
            ("sandile", "common", "20-35", 7), ("cubone", "uncommon", "25-40", 6),
            ("baltoy", "uncommon", "25-40", 6), ("trapinch", "uncommon", "25-40", 6),
            ("rhyhorn", "uncommon", "25-40", 5), ("hippopotas", "uncommon", "25-40", 5),
            ("onix", "uncommon", "25-40", 4), ("larvitar", "rare", "30-45", 3),
            ("gible", "rare", "30-45", 3), ("camerupt", "rare", "40-55", 2),
            ("aerodactyl", "rare", "40-55", 1),
        ],
    },
    "venus": {  # toxic furnace: fire / poison
        "biomes": ["ad_astra:venus_wastelands", "ad_astra:infernal_venus_barrens"],
        "blocks": ["ad_astra:venus_sand", "ad_astra:venus_stone", "ad_astra:venus_sandstone",
                   "ad_astra:venus_cobblestone", "minecraft:basalt", "minecraft:blackstone",
                   "minecraft:gravel"],
        "spawns": [
            ("slugma", "common", "25-40", 10), ("grimer", "common", "25-40", 10),
            ("koffing", "common", "25-40", 9), ("magby", "common", "25-40", 8),
            ("salandit", "common", "25-40", 8), ("torkoal", "uncommon", "30-45", 6),
            ("ekans", "uncommon", "30-45", 6), ("sizzlipede", "uncommon", "30-45", 6),
            ("litwick", "uncommon", "30-45", 5), ("darumaka", "uncommon", "30-45", 5),
            ("magmar", "rare", "40-55", 3), ("turtonator", "rare", "40-55", 2),
            ("larvesta", "rare", "35-50", 2), ("heatmor", "rare", "40-55", 2),
            ("lampent", "rare", "40-55", 2),
        ],
    },
    "mercury": {  # scorched metal world: steel
        "biomes": ["ad_astra:mercury_deltas"],
        "blocks": ["ad_astra:mercury_stone", "ad_astra:mercury_cobblestone",
                   "minecraft:basalt", "minecraft:blackstone", "minecraft:gravel"],
        "spawns": [
            ("magnemite", "common", "30-45", 10), ("aron", "common", "30-45", 10),
            ("klink", "common", "30-45", 9), ("durant", "common", "30-45", 8),
            ("ferroseed", "uncommon", "35-50", 6), ("skarmory", "uncommon", "35-50", 6),
            ("honedge", "uncommon", "35-50", 6), ("mawile", "uncommon", "35-50", 5),
            ("steelix", "rare", "45-60", 3), ("lairon", "rare", "40-55", 3),
            ("magneton", "rare", "45-60", 3), ("metang", "rare", "45-60", 2),
        ],
    },
    "glacio": {  # frozen planet: ice
        "biomes": ["ad_astra:glacio_snowy_barrens", "ad_astra:glacio_ice_peaks"],
        "blocks": ["minecraft:snow_block", "ad_astra:permafrost", "ad_astra:glacio_stone",
                   "ad_astra:glacio_cobblestone", "minecraft:deepslate", "minecraft:ice",
                   "minecraft:packed_ice"],
        "spawns": [
            ("swinub", "common", "30-45", 10), ("cubchoo", "common", "30-45", 10),
            ("smoochum", "common", "30-45", 8), ("bergmite", "common", "30-45", 8),
            ("seel", "common", "30-45", 7), ("sneasel", "uncommon", "35-50", 6),
            ("jynx", "uncommon", "35-50", 5), ("eiscue", "uncommon", "35-50", 5),
            ("amaura", "uncommon", "35-50", 4), ("cryogonal", "uncommon", "35-50", 4),
            ("shellder", "uncommon", "35-50", 4), ("piloswine", "rare", "45-60", 3),
            ("beartic", "rare", "45-60", 3), ("avalugg", "rare", "45-60", 2),
            ("weavile", "rare", "50-60", 2), ("cloyster", "rare", "45-60", 2),
            ("mamoswine", "rare", "55-65", 1),
        ],
    },
}


def build(planet: str, cfg: Dict) -> Dict:
    """Build one Cobblemon spawn-set document for a planet."""
    condition = {"biomes": cfg["biomes"], "neededBaseBlocks": cfg["blocks"]}
    spawns: List[Dict] = [
        {"id": f"omnipack-{planet}-{species}", "pokemon": species, "presets": [],
         "type": "pokemon", "context": "grounded", "bucket": bucket, "level": level,
         "weight": float(weight), "condition": condition}
        for species, bucket, level, weight in cfg["spawns"]
    ]
    return {"enabled": True, "neededInstalledMods": ["ad_astra"],
            "neededUninstalledMods": [], "spawns": spawns}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for planet, cfg in PLANETS.items():
        path = OUT_DIR / f"omnipack_{planet}.json"
        path.write_text(json.dumps(build(planet, cfg), indent=2) + "\n")
        print(f"{path.name}: {len(cfg['spawns'])} spawns")


if __name__ == "__main__":
    main()
