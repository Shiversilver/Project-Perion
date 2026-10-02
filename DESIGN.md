# Project Perion — Design Doc

*Living document. Update it as decisions are made.*

## Pitch

A top-down space sim where you're a lone frontier marshal. Take cases from
your station, hunt pirates and syndicates, and decide whether to talk,
threaten or shoot. Each choice decides what kind of peace the frontier
ends up with.

**Platform:** Steam / desktop (Windows, Mac, Linux). **Engine:** Godot 4.
**Inspirations:** Starsector (combat), Rebel Galaxy, Vanguard Galaxy,
Silent Hunter 3 (crew management).

## Pillars

1. **You are the law.** Not a trader or a pirate: a lawman with a mandate, a rank and a reputation.
2. **Methods matter.** Diplomacy, coercion and combat all work, and each has consequences.
3. **Weighty tactical combat.** Starsector-like flux, shields, armor and weapon groups.
4. **Your crew are people.** Silent Hunter 3-style crew management: who's at which station matters.
5. **A frontier you shape.** A handcrafted region whose systems visibly go from lawless to peaceful.

## Core loop

1. **Station:** review the case board (intel, threat level, reward).
2. **Investigate:** fly out, scan, talk to locals. Better intel gives better options.
3. **Confront:** diplomacy (dialogue, deals, amnesty), coercion (show of force,
   threats, blockades) or combat.
4. **Resolve:** outcomes shift system stability, faction attitudes, rank and reputation.
5. **Return:** get paid, refit, rest and rotate crew; new cases appear.

## Systems

### Combat (Milestone 1, in progress)
- Starsector feel: deliberate, inertial flight; turn, thrust, strafe.
- **Flux:** soft (weapons, shield upkeep) and hard (shield hits). Overload at max; manual venting.
- **Shields:** frontal arc, toggled. Hard flux only dissipates with shields down.
- **Damage types:** kinetic (anti-shield), high explosive (anti-armor), energy (even), fragmentation (weak).
- **Weapon groups:** 1–5, one manually aimed, others on autofire.
- Hardpoints (narrow arc, slow) vs turrets (wide arc).

### Crew management (planned, inspired by Silent Hunter 3)
Draft ideas to refine together:
- Crew assigned to **stations**: helm, weapons, engineering, sensors/comms, damage control.
- Station efficiency comes from who's assigned: qualifications, experience, fatigue.
- **Fatigue and shifts:** crew tire on long patrols; rotate watches or performance drops.
- **Officers** with specialties boost their station (faster turret tracking, better flux handling, better repairs).
- **Injuries and losses** in combat: hull hits can wound crew at the affected station.
- **Experience and promotions** after missions; medals and commendations.
- Morale tied to your reputation and methods: some crew may object to coercion or executions.
- Combat hook: station efficiency feeds directly into ship stats (weapon turn rate, shield efficiency, repair speed, engine output).

### Narrative (to be designed in a dedicated session)
- An authored main arc woven through handcrafted cases.
- Recurring characters: spared pirates return, bosses hold grudges.
- Reputation axes (e.g. feared vs trusted vs corrupt) that NPCs react to.

### World
- **Handcrafted** frontier region, roughly 5–10 star systems.
- Each system has a stability level, from lawless to peaceful.
- Factions: Perion Frontier Authority (you), pirate clans, syndicates, locals, others TBD.

### Progression
- Rank in the Frontier Authority unlocks ships, assignments and authority (e.g. offering amnesty).
- Ship refits: weapons, modules. Whether you can change ships is TBD.

## Milestones

- [x] **M1 Fly and Fight:** flight model, flux/shields/armor, weapon groups, pirate AI, HUD, waves.
- [ ] **M1.5 Combat polish:** feel tuning from playtesting, sounds, better effects, more weapons.
- [ ] **M2 Station and case board:** dock, pick an assignment, fly to a target, return and get paid.
- [ ] **M3 Confrontation:** hailing, dialogue, the three approaches (diplomacy / coercion / combat).
- [ ] **M4 Crew v1:** stations, assignments, fatigue, effect on ship stats.
- [ ] **M5 Frontier map:** handcrafted systems, travel, system stability.
- [ ] Narrative design session, then a vertical slice of the main arc.

## Open questions

- Single ship forever, or can you acquire new hulls?
- Real-time or pausable crew management during combat?
- How permanent is crew death?
- Art direction for the final look (currently placeholder vector shapes).
