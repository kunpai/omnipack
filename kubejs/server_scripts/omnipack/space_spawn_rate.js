// Omnipack: faster Pokémon spawning on Ad Astra planets
//
// Planets are barren (lots of lava, spires, ice), so many of Cobblemon's spawn
// attempts land on invalid ground. Each player has their own Cobblemon spawner;
// its tick timer counts down by tickTimerMultiplier per tick, so a multiplier of
// 4 means 4x the spawn attempts. Only players standing on a planet are boosted.

;(function () {
  let SpawnerManager = Java.loadClass('com.cobblemon.mod.common.api.spawning.CobblemonWorldSpawnerManager')

  let SPACE_SPAWN = {
    PLANETS: ['ad_astra:moon', 'ad_astra:mars', 'ad_astra:venus', 'ad_astra:mercury', 'ad_astra:glacio'],
    MULTIPLIER: 4.0, // spawn attempts on planets vs. normal
    CHECK_EVERY_TICKS: 20,
  }

  let tick = 0
  let loggedError = false

  /** Dimension id of the player's current level, e.g. "ad_astra:moon". */
  function dimensionOf(player) {
    // KubeJS exposes Level#dimension() as a property
    let d = player.level.dimension
    return String(d && d.location ? d.location() : d)
  }

  ServerEvents.tick(event => {
    tick++
    if (tick % SPACE_SPAWN.CHECK_EVERY_TICKS !== 0) return
    let spawners = SpawnerManager.INSTANCE.getSpawnersForPlayers()

    event.server.getPlayerList().getPlayers().forEach(player => {
      try {
        let spawner = spawners.get(player.uuid)
        if (!spawner) return
        let onPlanet = SPACE_SPAWN.PLANETS.indexOf(dimensionOf(player)) >= 0
        let wanted = onPlanet ? SPACE_SPAWN.MULTIPLIER : 1.0
        if (spawner.getTickTimerMultiplier() !== wanted) spawner.setTickTimerMultiplier(wanted)
      } catch (e) {
        if (!loggedError) {
          console.error(`[omnipack] space_spawn_rate: ${e}`)
          loggedError = true
        }
      }
    })
  })
})()
