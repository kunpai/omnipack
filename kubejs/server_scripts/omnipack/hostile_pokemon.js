// Omnipack: hostile wild Pokémon
//
// Which: wild Pokémon with a Ghost/Dark/Dragon/Poison type, plus a random
// 10% of all other wild Pokémon. Rolled once per Pokémon and saved on it.
//
// What they do:
//   - Normal hostiles chase the player and force a battle on contact.
//     If the player has no Pokémon able to fight, they attack directly.
//   - Strong hostiles (legendary/mythical/ultra beast, or STRONG_LEVEL_GAP+
//     levels above the player's best healthy party member) attack directly.
//
// Never aggro: Peaceful difficulty, Creative/Spectator, or a player already
// in a battle. After a battle ends the Pokémon waits BATTLE_COOLDOWN ticks.

const PokemonEntity = Java.loadClass('com.cobblemon.mod.common.entity.pokemon.PokemonEntity')
const BattleBuilder = Java.loadClass('com.cobblemon.mod.common.battles.BattleBuilder')
const SuccessfulBattleStart = Java.loadClass('com.cobblemon.mod.common.battles.SuccessfulBattleStart')
const PlayerExt = Java.loadClass('com.cobblemon.mod.common.util.PlayerExtensionsKt')

const HOSTILE = {
  SCARY_TYPES: ['ghost', 'dark', 'dragon', 'poison'],
  RANDOM_CHANCE: 0.10,
  SCAN_EVERY_TICKS: 10,
  AGGRO_RANGE: 16,
  ENGAGE_RANGE: 2.5,
  CHASE_SPEED: 1.3,
  STRONG_LEVEL_GAP: 10,
  BATTLE_COOLDOWN: 600, // 30 s
  ATTACK_COOLDOWN: 30, // 1.5 s
  BASE_DAMAGE: 2,
  DAMAGE_PER_LEVEL: 1 / 8,
  MAX_DAMAGE: 12,
}

const KEY_ROLLED = 'omnipack_hostile_rolled'
const KEY_HOSTILE = 'omnipack_hostile'
const KEY_NEXT = 'omnipack_hostile_next'

let loggedError = false

/** Decide (once) whether this wild Pokémon is hostile, and remember it. */
function isHostile(entity, pokemon) {
  const data = entity.persistentData
  if (!data.getBoolean(KEY_ROLLED)) {
    let scary = false
    const types = pokemon.getTypes().iterator()
    while (types.hasNext()) {
      const name = String(types.next().getName()).toLowerCase()
      if (HOSTILE.SCARY_TYPES.indexOf(name) >= 0) scary = true
    }
    data.putBoolean(KEY_HOSTILE, scary || Math.random() < HOSTILE.RANDOM_CHANCE)
    data.putBoolean(KEY_ROLLED, true)
  }
  return data.getBoolean(KEY_HOSTILE)
}

/** Highest level among the player's non-fainted party Pokémon (0 if none). */
function bestPartyLevel(player) {
  let best = 0
  const it = PlayerExt.party(player).iterator()
  while (it.hasNext()) {
    const p = it.next()
    if (p && !p.isFainted() && p.getLevel() > best) best = p.getLevel()
  }
  return best
}

function isStrong(pokemon, best) {
  return pokemon.isLegendary() || pokemon.isMythical() || pokemon.isUltraBeast() ||
    pokemon.getLevel() >= best + HOSTILE.STRONG_LEVEL_GAP
}

function attackDirectly(entity, pokemon, player, now) {
  const dmg = Math.min(HOSTILE.MAX_DAMAGE, HOSTILE.BASE_DAMAGE + pokemon.getLevel() * HOSTILE.DAMAGE_PER_LEVEL)
  player.hurt(entity.damageSources().mobAttack(entity), dmg)
  entity.persistentData.putLong(KEY_NEXT, now + HOSTILE.ATTACK_COOLDOWN)
}

function handle(entity, player, server, now) {
  const pokemon = entity.getPokemon()
  if (!pokemon || !pokemon.isWild() || !entity.isAlive()) return
  if (!isHostile(entity, pokemon)) return

  const data = entity.persistentData
  if (entity.isBattling()) {
    data.putLong(KEY_NEXT, now + HOSTILE.BATTLE_COOLDOWN)
    return
  }
  if (now < data.getLong(KEY_NEXT)) return

  if (entity.distanceTo(player) > HOSTILE.ENGAGE_RANGE) {
    entity.getNavigation().moveTo(player, HOSTILE.CHASE_SPEED)
    if (now % 40 === 0) {
      server.runCommandSilent(`particle minecraft:angry_villager ${entity.x} ${entity.y + entity.bbHeight + 0.3} ${entity.z} 0.2 0.1 0.2 0 2`)
    }
    return
  }

  const best = bestPartyLevel(player)
  if (best > 0 && !isStrong(pokemon, best)) {
    const result = BattleBuilder.INSTANCE.pve(player, entity)
    if (result instanceof SuccessfulBattleStart) {
      data.putLong(KEY_NEXT, now + HOSTILE.BATTLE_COOLDOWN)
      return
    }
  }
  attackDirectly(entity, pokemon, player, now)
}

ServerEvents.tick(event => {
  const server = event.server
  if (server.getTickCount() % HOSTILE.SCAN_EVERY_TICKS !== 0) return

  server.getPlayerList().getPlayers().forEach(player => {
    if (player.isCreative() || player.isSpectator()) return
    const level = player.level()
    if (level.getDifficulty().getId() === 0) return
    if (PlayerExt.isInBattle(player)) return

    const now = level.getGameTime()
    const box = player.getBoundingBox().inflate(HOSTILE.AGGRO_RANGE)
    level.getEntities(player, box).forEach(entity => {
      if (!(entity instanceof PokemonEntity)) return
      try {
        handle(entity, player, server, now)
      } catch (e) {
        if (!loggedError) {
          console.error(`[omnipack] hostile_pokemon: ${e}`)
          loggedError = true
        }
      }
    })
  })
})
