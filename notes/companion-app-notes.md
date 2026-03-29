# Space Empires 4X Companion Notes

## Goal

Build a Flutter companion app for `Space Empires 4X` focused on in-game assistance and accounting, with the production sheet as the main value add.

## Source Files

- `MasterRulebook.pdf`
- `ProductionSheet.pdf`
- `ProductionSheetNoFacilities.pdf`

## Current Understanding

- The app should not be a generic score tracker. It should directly support the game loop and the bookkeeping load of the physical game.
- The production sheet is the highest-value workflow and should drive the first usable app screens.
- Both production sheet variants matter:
  - with facilities
  - without facilities
- The app should support switching rulesets cleanly rather than baking facilities into the base model.
- The app should support selective expansions, not just all-or-nothing `All Good Things`.
- Best approach: treat expansions and optional rules as composable feature flags that unlock rules, fields, and UI modules.

## Rulebook Structure Extracted

Primary base-rule sections from the master rulebook:

- `3.0` Sequence of Play
- `4.0` Movement Phase
- `5.0` Combat Phase
- `6.0` Exploration
- `7.0` Economic Phase
- `8.0` Basic Unit Types
- `9.0` Technology

Important bookkeeping-heavy subsections:

- `7.1` Collect Colony Income
- `7.2` Collect Mineral Income
- `7.3` Pay Maintenance Costs
- `7.4` Bid to Determine Player Order
- `7.5` Purchase Units & Technology
- `7.6` Place Purchased Units
- `7.7` Adjust Colony Income
- `7.8` Maintenance Increase & Decrease

Optional rules especially relevant to accounting:

- `28.0` Optional Deep Space Discoveries
- `36.0` Facilities (IC/RC/LC/TC)
- `38.0` Advanced Construction
- `39.0` Resource Cards
- `40.0` Replicators

## Product Direction

Initial app pillars:

1. Game setup
2. Turn and phase tracker
3. Production and accounting
4. Rules reference by phase

Expansion-aware product direction:

- Base game should work on its own.
- Expansions should be individually toggled where the rulebook structure allows it.
- Optional rules should be toggled separately from expansion ownership.
- UI and calculations should expose only the fields relevant to the active ruleset.

Likely MVP:

- create a game
- add players/empires
- choose optional rule toggles
- track current turn and phase
- track CP income and spending
- track maintenance
- track colonies/homeworld values
- track technologies
- track purchases and placement reminders
- browse/search rule sections

## Production Sheet Extraction Status

- `MasterRulebook.pdf`: text extraction works with `pypdf`
- `ProductionSheet.pdf`: appears image-based, text extraction empty
- `ProductionSheetNoFacilities.pdf`: appears image-based, text extraction empty

- Rendered inspection results:

- `ProductionSheetNoFacilities.pdf` page 1:
  - CP carry-over
  - colony CP
  - mineral/resource card CP
  - MS pipeline LP
  - total
  - maintenance
  - turn order bid
  - technology spending
  - ship spending
  - remaining CP
  - CP spent on upgrades
  - maintenance increase / decrease tracker
- `ProductionSheet.pdf` page 1 adds facilities support:
  - LP track with colony/facility LP, maintenance, LP placed on LC colonies, remaining LP
  - CP track with colony/facility CP, mineral/resource card CP, MS pipeline LP, penalty LP, turn order bid, purchases, upgrades
  - RP track with colony/facility RP and technology spending
  - TP track with colony/facility TP and TP spending
- Both sheets include a technology progression area.
- Both sheet variants share the same ship technology sheet on page 2.

Relevant rules mapped to the sheets:

- `7.0` economic phase defines the base production sequence
- `7.5.2` carry-over cap: `30 CP`
- `7.8` maintenance increase/decrease is explicitly a tracking aid
- `36.0` facilities introduces:
  - `IC` => CP
  - `RC` => RP
  - `LC` => LP
  - `TC` => TP
- `36.5` changes maintenance and bidding to LP and introduces out-of-supply logic
- `36.6` introduces TP and temporal effect spending

Next step:

- convert the sheet layout into a structured data model
- build the first production dashboard UI around those rows
- add rule toggles for:
  - facilities
  - logistic centers
  - temporal centers
  - advanced construction
  - replicators

## Build Status

- Flutter project created in `C:\programmieren\se4x`
- Working notes file created and should be kept current during implementation
- Current Flutter structure:
  - `lib/main.dart` => app entry point
  - `lib/app_shell.dart` => app shell and top-level state
  - `lib/models/companion_models.dart` => config, ruleset toggles, turn state, production state
  - `lib/pages/command_deck_page.dart` => game setup and turn flow
  - `lib/pages/production_page.dart` => production-sheet-driven accounting UI
  - `lib/pages/rules_page.dart` => lightweight rules reference spine
  - `lib/widgets/companion_widgets.dart` => shared UI building blocks
- The first usable shell now supports:
  - selective expansion ownership toggles
  - optional rule toggles for facilities, logistics, temporal centers, advanced construction, and replicators
  - production ledgers for base mode and facilities mode
  - technology level tracking
  - turn/phase tracking
- Validation:
  - `flutter analyze` passes
  - `flutter test` passes

## Next Implementation Priorities

- Expand world and fleet tracking into fuller game-state modeling beyond economic bookkeeping.
- Model supply range on the map rather than only flagging fleet stacks as in/out of supply manually.
- Add ship groups and tie upgrade/refit tracking to actual fleet composition and tech levels.
- Expand the rules reference into searchable structured content extracted from the PDFs.

## Derived Bookkeeping Status

The app now derives the production sheet from tracked empire state instead of relying only on manual ledger entry.

Tracked state now includes:

- `WorldState`
  - name
  - homeworld or colony
  - colony value
  - blockade flag
  - facilities on the world
  - mineral income waiting to collect
  - MS pipeline income waiting to collect
- `FleetRosterEntry`
  - ship type
  - total quantity
  - out-of-supply quantity

Fleet tracking now uses a roster model:

- ship defaults are attached to canonical `ShipType` definitions
- hull size and maintenance exemption are no longer typed manually per stack
- fleet editing is grouped by ship class instead of arbitrary stack rows
- this reduces bookkeeping drift and makes maintenance calculations rules-aware by default

Fleet tracking has now been extended from pure class totals into cohorts:

- multiple cohorts may exist under the same ship class
- each cohort carries:
  - quantity
  - out-of-supply quantity
  - profile label
  - optional location tag
- this is intended to represent bookkeeping identity, not exact hidden counter identity
- it gives a middle ground between:
  - one total number per ship class
  - a full map mirror of every hidden stack

Ship upgrade tracking now exists at the cohort level:

- new cohorts snapshot the current empire baseline for:
  - attack
  - defense
  - tactics
  - move
- cohorts can store:
  - profile label
  - location tag
  - refit CP note
  - special note
- the app still does NOT mirror exact hidden board groups; cohorts remain bookkeeping identities

World editing now also follows a more sheet-like structure:

- dedicated `Homeworld` section
- colony roster rows instead of a generic wall of world cards
- facilities remain tied to each world but are presented in a faster economic-phase workflow

## Discoverability Status

The app now includes lightweight onboarding and contextual help:

- first-run setup overlay with starter presets:
  - base game
  - base + close encounters
  - all good things economy
- command-page help cards explaining:
  - where expansions are chosen
  - ownership vs optional rules
  - why facilities change bookkeeping so much
- production-page help card explaining which values are derived vs manually entered
- ship type guide cards with short rule-oriented summaries per ship class

Derived outputs now include:

- colony/facility CP
- colony/facility LP
- colony/facility RP
- colony/facility TP
- mineral CP
- MS pipeline CP
- maintenance in CP or LP depending on active rules
- LP shortfall conversion penalty into CP
- out-of-supply ship count
- maintenance derived from roster defaults per ship type

Current limitation:

- supply range is not yet computed from map state; `inSupply` is currently a manual fleet flag
- bidding, upgrades, and research spending still have manual inputs, which is appropriate because they are player decisions rather than passive game-state

## Persistence Status

The app now persists the main companion state locally as JSON in the user's profile/config area.

Persisted state includes:

- onboarding visibility
- expansion ownership and optional-rule toggles
- turn number and current phase
- production ledger values
- tech levels
- worlds and facilities
- fleet cohorts, locations, cohort tech profiles, and refit notes

Implementation notes:

- persistence is file-based rather than plugin-based
- this avoids extra package dependencies for a single state blob
- the app shell auto-loads on startup and auto-saves on state changes
- the header menu now exposes:
  - show onboarding
  - reset saved game

Tests now cover:

- persisted state JSON round-trip
- normalization of restored state against the active config
- file-store save/load/clear behavior
- widget-level restore and reset flow

## Turn History Status

Turn flow now has real session history rather than only a mutable live snapshot.

Current behavior:

- `Undo` and `Redo` operate on app-level checkpoints
- `End Turn`:
  - archives the full current state as a turn snapshot
  - advances to the next turn
  - resets the phase to `Movement`
- undoing `End Turn` also removes the newly created turn snapshot
- restoring a turn snapshot is itself undoable

Important design choice:

- `End Turn` does not auto-clear economic inputs yet
- this is deliberate to avoid silent data loss while the app is still gaining stronger turn-transition rules

## Rules UX Status

The Rules tab is now becoming a real navigator rather than a static spine.

Current behavior:

- rules are defined in a central catalog with:
  - code
  - title
  - short summary
  - longer practical detail
  - tags
- the Rules tab now supports:
  - search
  - focused rule view
  - tappable reference spine
- command and production workflows now expose direct rule-jump chips
- tapping a rule chip switches to the Rules tab and focuses that section

Current coverage:

- turn-flow and configuration areas jump to phase/economic/facilities rules
- ledger sections jump to the relevant accounting rules
- world, fleet, and ship guide areas jump to the most relevant colony, maintenance, ship, and tech rules

Latest upgrade:

- focused rules now support multi-section bundles instead of only single-section jumps
- production workflow now has bundle entry points for:
  - colony income and blockades
  - facilities income and construction
  - fleet bookkeeping
  - refits
  - out-of-supply logistics
- ship guide cards now expose ship-type-specific rule bundles
- the rules catalog now includes several finer-grained subsection entries such as:
  - `7.1.2`
  - `7.3.2`
  - `7.5.2`
  - `7.5.4`
  - `9.11.2`
  - `21.7.4`
  - `36.2.1`
  - `36.5.1`
  - `36.5.3`
  - `38.1.1`
  - `38.1.2`
  - `38.1.3`

UX polish pass:

- command page now has a `Phase Assistant` section with:
  - phase-specific focus text
  - quick step chips
  - direct playbook opening for the active phase
- command page now also has a dedicated `Combat Lens` section for battle resolution
- rules page now has `Rule Playbooks` for grouped tasks instead of requiring users to search from scratch

Combat rules upgrade:

- the rules catalog now goes much deeper on section `5.0` with actual extracted subsection text for:
  - `5.1` through `5.1.5`
  - `5.2`
  - `5.3`
  - `5.4`
  - `5.5`
  - `5.6`
  - `5.7`
  - `5.7.1`
  - `5.8`
  - `5.8.1`
  - `5.8.2`
  - `5.9`
  - `5.9.1`
  - `5.10`
  - `5.10.1`
  - `5.10.2`
  - `5.10.3`
  - `5.11`
- this is now enough to support a real `Combat Deep Dive` playbook instead of only pointing at generic `5.0`

Further rules deepening:

- movement coverage now includes:
  - `4.1`
  - `4.1.1`
  - `4.1.2`
  - `4.1.3`
  - `4.2`
  - `4.3`
  - `4.4.1`
  - `4.4.2`
- exploration coverage now includes:
  - `6.1`
  - `6.2`
  - `6.3`
  - `6.4`
  - `6.5`
  - `6.6`
  - `6.7`
  - `6.7.1`
  - `6.7.2`
  - `6.7.3`
  - `6.8`
  - `6.8.1`
  - `6.8.2`
- economy coverage now includes more procedure-level entries:
  - `7.1.1`
  - `7.3.1`
  - `7.5.1`
  - `7.5.3`
  - `7.5.5`
  - `7.6.1`
  - `7.6.2`
  - `7.7.1`
  - `7.7.2`
- unit / deception coverage now includes:
  - `8.3`
  - `8.3.2`
  - `8.3.3`
- technology coverage now includes:
  - `9.1`
  - `9.2`
  - `9.3`
  - `9.4`
  - `9.5`
  - `9.7`
  - `9.9`
  - `9.10`
  - `9.11`
  - `9.11.1`
  - `9.11.4`

New playbooks now cover:

- `Movement And Positioning`
- `Exploration And Discoveries`
- `Economy And Production`
- `Ships, Builds, And Refits`
- `Technology Progression`

Contextual rule prompt pass:

- command page now exposes phase-specific prompt chips like:
  - terrain entry
  - colonization
  - fast and exploration
  - hazards
  - minerals
  - space wrecks
  - carry-over cap
  - hidden builds
  - refits
- production page now exposes state-aware prompt cards when relevant, including:
  - blocked worlds
  - minerals waiting
  - supply risk
  - refits recorded
- technology progression now has per-technology rule chips so tapping `Attack`, `Move`, `Terraforming`, etc. opens a focused rule packet instead of a generic tech section
- colony rows now have tighter chips for:
  - blockade
  - mineral collection
  - colony growth
- fleet cohort rows now have tighter chips for:
  - refit tracking
  - group tech / group uniformity
  - out of supply

General UX pass:

- the app now uses custom number-entry controls instead of relying on mobile number keyboards for most bookkeeping-heavy interactions
- the shared `CompactNumberSpinner` supports:
  - tap-to-open numeric pad
  - plus/minus nudges
  - quick presets on the number pad
- ledger rows now use the custom number control instead of raw numeric text fields
- tech cards now use the same control language for level changes
- colony/fleet steppers and refit CP also use the custom number control pattern

Motion and feel:

- header, stat cards, and section cards now use light reveal animation on load
- the header rocket now does a finite entrance wobble instead of a perpetual animation
- the UI uses more subtle elevation and transition polish without turning bookkeeping screens into noise

Easter eggs:

- there are now 20 hidden flavor messages distributed through tooltip surfaces like:
  - header icon
  - header pills
  - stat cards
  - section sparkle markers
  - number spinners

Persistent UX pass:

- persistence is no longer a single anonymous session blob
- the save file now stores a lightweight game library with:
  - active game id
  - named game slots
  - full per-game session state
- each saved game keeps its own:
  - current app state
  - undo stack
  - redo stack
  - turn history
- the app now resumes the last active game automatically
- the header state menu now supports:
  - switch game
  - save as new game
  - rename active game
  - delete active game
  - show onboarding
  - reset saved game
- old single-session save files are migrated into the new one-slot library format automatically

## Rules Source Status

The rules catalog now uses extracted text from `MasterRulebook.pdf` rather than app-authored summaries as the primary content.

Current approach:

- each `RuleSection` now carries:
  - rule code
  - title
  - actual excerpt text from the extracted PDF
  - source page number
  - tags
- the focused Rules view explicitly identifies the text as coming from the extracted rulebook
- ship-guide rule jumps were corrected to target rules that actually match the unit better

Known improvements made in this pass:

- `Missile Boat` no longer points at `24.0` generically; it now points at the Alternate Empires unit rule
- several ship guide jumps now target more precise sections like:
  - `8.1` Bases
  - `8.2` Shipyards
  - `8.4` Colony Ships
  - `15.1` Carriers
  - `15.2` Fighters
  - `16.1` Raiders
  - `16.2` Scanners
  - `19.1` / `19.2` Boarding
  - `21.1` / `21.7` Transports and landing
  - `22.0` Titans
  - `23.0` Flagships

Future rulebook work:

- extend the extracted catalog to more subsections and optional rules
- add more exact entries where current references still land on a broader section than ideal
- potentially store the extracted rule text outside Dart code if the catalog grows large enough

## Current UX State

The app now has five first-class navigation surfaces:

- `Command`
- `Production`
- `Combat`
- `Rules`
- `Games`

This is deliberate. The app has enough persistent state now that game management and combat flow should not be hidden behind a small header menu.

## Game Library Pass

Named game-slot persistence is now exposed through a dedicated `Games` page instead of relying on the header menu alone.

Current game-library behavior:

- each saved game slot stores:
  - name
  - updated time
  - archived flag
  - full session state
- the `Games` page shows:
  - active game
  - recent games
  - archived games
  - ruleset summary
  - turn / phase summary
  - last played text
- supported actions:
  - create new game
  - duplicate any game
  - rename any game
  - archive / restore any game
  - delete any game except the last remaining slot
  - switch active game

Behavior retained:

- the app still resumes the last active game automatically
- the save file is still a named game-slot library, not separate files per game
- old single-session saves still migrate into a one-slot library

## Turn Transition Intelligence

`End Turn` is no longer a blind archive/increment button.

Current end-turn flow:

- `Review and End Turn` opens a checklist sheet
- the user must explicitly confirm:
  - bids resolved
  - builds placed
  - colony growth applied
  - maintenance deltas reviewed
  - refits reviewed
- each checklist item has direct rule jumps / playbook access
- only after the checklist is confirmed does the app:
  - archive the current turn as a snapshot
  - advance to the next turn
  - reset phase to `Movement`

Important behavior:

- `Undo` still rewinds the full end-turn transition
- that means an accidental or premature confirmation can still be reversed cleanly
- the flow does not auto-clear economic values or mutate production state beyond turn/phase advancement

## Combat Helper

There is now a dedicated `Combat` page rather than only a combat reference card on the Command page.

Current combat helper scope:

- it is a sequence assistant, not an auto-resolver
- it tracks a lightweight battle card with:
  - battle label
  - attacker
  - defender
  - stakes
  - notes
  - completed combat steps
- it persists as part of app state, so the live combat checklist survives saves and app restarts

Current guided combat steps:

1. reveal and battle setup
2. screening
3. fleet size bonus
4. firing order
5. fire resolution and damage
6. retreats
7. colony attack and post-combat

Each step includes:

- plain-English guidance
- quick rule chips
- a bundled rule playbook button

## Current Next-Best UX Ideas

The strongest follow-on improvements after this pass are:

- better active-game summaries on the `Games` page
- import/export or printable snapshot summaries
- richer turn snapshot browsing with notes
- combat helper support for temporary round-by-round notes without becoming a full battle simulator

## QA Pass Notes

Core bookkeeping review findings that were fixed:

- `End Turn` previously archived state and advanced the turn without rolling forward next-turn carry-over values
- turn-close was available outside the Economic phase, which invited an invalid main gameflow transition
- logistics bookkeeping could treat manually marked Scouts and Raiders as out of supply even though the rules exempt them

Current behavior after the fix:

- during an Economic-phase end turn, the app now carries remaining resources into the next turn:
  - `CP` rolls forward with the `30 CP` cap
  - `LP`, `RP`, and `TP` roll forward in facilities mode
- per-turn spend / bid fields are cleared on rollover:
  - bids
  - CP ship spending
  - CP upgrade spend
  - RP tech spending
  - TP spending
  - maintenance delta note rows
- `Review and End Turn` is disabled outside the Economic phase
- Scouts and Raiders ignore OoS penalties in logistics mode

Tests added in this QA pass:

- `prepareForNextTurn` rolls forward remaining values correctly
- `prepareForNextTurn` enforces the CP carry-over cap
- Scouts / Raiders ignore OoS penalties in logistics mode
- widget coverage for:
  - reviewed end-turn rollover
  - end-turn disabled outside Economic phase

## Facility Timing Pass

The earlier review gap around `36.2.1` is now addressed.

Current facility model:

- each world now has:
  - `Active` facilities for the current Economic Phase
  - `Next Economic Phase` facilities for staging builds/replacements that should not pay out yet
- derived income only uses `Active` facilities
- when the turn rolls forward, staged facilities become active and the staged slot is cleared

Why this matters:

- it prevents a newly built facility from incorrectly generating income in the same Economic Phase
- it also handles replacement timing more cleanly than a single raw facility field

## Production UX Trim

The top of the Production page was starting to duplicate itself.

Current approach:

- the planning strip is now the primary resource-planning surface
- the old top-level resource stat-card cluster was trimmed back
- only the non-duplicative high-level counts remain there:
  - tracked worlds
  - fleet classes

This keeps the page more readable while preserving the stronger planning HUD and warning lane.

## Facility Enforcement Pass

Facility timing is no longer only model-correct; the workflow now pushes users toward the rule-safe path.

Current approach:

- `Active` facilities are shown as a read-only summary row for current-turn income
- `Next Economic Phase` is the editable row for normal facility builds and replacements
- the active row still has an explicit correction action for setup fixes and live-game repair

Rule enforcement now surfaces explicit reasons when a facility action is blocked:

- not in the Economic phase
- world is blocked
- colony is below growth marker `1`

Relevant extracted rules this pass was checked against:

- `36.1` homeworld starting facilities and first-turn resource mix
- `36.2.1` facility cost, timing, removal/replacement timing, and build eligibility
- `36.2.2` facility income conversion
- `36.5.2` / `36.5.3` Scouts and Raiders always in supply

## App Icon Pass

`AppIcons.zip` is now wired into the project as real platform icons instead of leaving the default Flutter launcher assets in place.

Implemented:

- Android legacy launcher icons replaced for all density buckets
- Android adaptive icons added with `ic_launcher.xml` and `ic_launcher_round.xml`
- a matching launcher background color was added so Android uses masked launcher icons instead of a fallback square asset path
- iOS app icon sizes regenerated from the provided 1024 source art
- macOS app icon set regenerated from the same source
- web favicon and manifest icons replaced
- Windows `.ico` regenerated with native icon sizes

Android note:

- the icon art from the ZIP is full-bleed artwork with its own background, not a transparent logo on white
- adaptive icon resources now point at that artwork through the proper launcher pipeline so it does not end up as a random square dropped into a white circle

## UX And Rule Pass

This pass focused on three things:

- reduce friction when jumping into the Rules tab from live workflows
- tighten rule-link accuracy in the combat helper
- add a few higher-value rule surfaces instead of just dumping more sections into search

Implemented:

- focused rule jumps now expose an explicit `Back to ...` action so users can return to the workflow that opened the Rules tab
- the end-turn review now shows a compact summary strip for:
  - next CP carry-over
  - build spend
  - staged facilities
  - refit notes
- the facility editor now has direct facility-rule links plus a staged-facility reminder that the change costs `5 CP` and does not pay out this turn
- production context prompts now surface:
  - staged facility timing/cost reminders
  - placement and shipyard-capacity review when ship spending is recorded
- the Rules page now has dedicated playbooks for:
  - `Facilities And Supply`
  - `Colony Damage And Recovery`

Combat helper rule cleanup:

- screening now points at screening rules instead of generic firing sections
- fleet-size bonus now points at `5.1.3`
- firing order now points at `5.2` plus terrain special conditions
- fire resolution now points at damage/boarding sections rather than colony-attack sections
- retreats now point at `5.9` / `5.9.1`
- colony attack/post-combat now points at colony attack, bombardment, landing, and post-combat aftermath sections

This was another consistency pass, not a claim of full rulebook completeness. The app still uses selected extracted rules where they add direct workflow value.

## Explicit World State Pass

This pass replaced two important bookkeeping shortcuts with explicit tracked state:

- colony facility legality no longer relies only on raw colony CP value
- homeworld damage/recovery no longer relies on a fixed assumed starting value

World state now tracks:

- `growthMarkerLevel` for colonies
- `homeworldValue` for current homeworld output

Why this matters:

- facility legality now checks the actual growth-marker state instead of inferring it only from current colony income
- colony damage and later recovery can be represented directly in the app
- damaged homeworld bookkeeping can now reduce or restore homeworld income explicitly

Current UX:

- colonies now edit `Growth marker` directly and show the resulting current CP output
- homeworlds now edit `Current value` directly in five-CP steps
- both surfaces link to the relevant colony-damage / recovery rules

## Combat Round Notes Pass

The combat helper now supports lightweight round-by-round notes without becoming a simulator.

Combat state now persists:

- a list of round notes
- each round note tracks:
  - round number
  - summary
  - damage/losses
  - retreats / position changes
  - loose notes
  - resolved/open state

UX:

- `Add round note`
- per-round cards
- clear-all rounds
- notes persist in saved app state and across tab changes

## End Turn Timing Pass

Growth and recovery suggestions are now wired into turn advancement with the correct timing model.

Current behavior:

- current-turn income still uses the already-tracked damaged colony/homeworld state
- the end-turn review now proposes:
  - colony growth steps
  - damaged homeworld recovery steps
- those suggestions are opt-in/visible in the review and do not silently mutate the sheet earlier in the Economic Phase
- if confirmed, the reviewed state is treated as the true `end of turn` snapshot
- next-turn rollover then happens from that reviewed state
- Undo still restores the pre-review state

This matches the current extracted rule interpretation:

- `7.1.1` colony income first
- `7.7.1` colony growth after the rest of Economic Phase bookkeeping
- `7.7.2` damaged homeworld recovery as part of Economic Phase progression
- `5.10.3` damaged colonies still provide reduced income this turn and still grow

## World State Polish Pass

This pass made world state more visual and more transparent instead of leaving it as raw number entry.

Implemented:

- homeworlds now show a `Recovery Track`
- colonies now show a `Growth Track`
- both tracks make the distinction between:
  - current value used for this turn’s income
  - projected next-turn value if end-turn growth/recovery is confirmed
- production HUD now surfaces `Queued Facilities` cost as a visible manual CP reminder when facility changes are staged
- production context prompts now include:
  - `Growth Pending`
  - `Homeworld Recovery Pending`

Result:

- derived bookkeeping is more transparent because the page now explains what counts now vs what changes at turn close
- users get a visual answer to “why did this world pay this much now and change later?”

## Combat Round Notes Polish

Round notes are still lightweight, but faster to use now.

Implemented:

- resolved rounds collapse by default
- quick tags append common round-story tokens like:
  - screening
  - fleet size
  - damage
  - retreat
  - colony attack
- `Duplicate to next round` copies the useful context forward without copying damage blindly

## Narrow Rule Audit

Focused audit against the extracted rule text:

- `7.1.1`: current-turn income uses the current damaged colony/homeworld state
- `7.7.1`: colony growth still happens after the rest of Economic Phase bookkeeping
- `7.7.2`: damaged homeworld recovery is handled as an Economic Phase progression step and is now suggested at end turn instead of being applied retroactively
- `5.10.2`: colony and homeworld damage are represented as stepped reductions in tracked world state
- `5.10.3`: damaged colonies still produce reduced income this turn and are still eligible to grow
- `36.2.1`: facilities remain blocked until growth marker `1` and staged facilities still wait until the next Economic Phase
- `36.2.2`: facility conversion still uses only active facilities for current-turn income

Conclusion:

- the audited timing logic is consistent with the extracted rulebook sections above
- the main remaining manual part is that combat damage itself is still entered by the user rather than being resolved automatically by the app

## HUD Pass

The old in-page planning block was too heavy.

Implemented:

- moved the live resource readout into a global top-of-screen HUD under the main header
- the HUD now behaves more like an RTS resource bar:
  - `CP` as the primary number
  - `Income`
  - `Maint.`
  - `RP`, `LP`, and `TP` when relevant
  - compact warning pills with exclamation icons for:
    - carry cap
    - out-of-supply ships
    - LP shortfall
    - blocked homeworld
    - pending purchases
- production no longer leads with the oversized planning strip; it now points users to the pinned HUD and returns focus to the ledger itself

Related UX slimming:

- Production was kept spreadsheet-first
- the big planning widget is no longer the first thing on the page
- compact rule/help affordances stay available without dominating the screen

## Technology Spending Pass

Technology spending is now tied to the actual production math instead of being a disconnected level tracker.

Implemented:

- technology purchase mode:
  - `Levels`
  - `Dice`
- per-technology editable cost field
- purchases immediately update:
  - `techSpendingCp` in base mode
  - `techSpendingRp` in facilities mode
- affordability is enforced against the live remaining research pool
- level mode allows at most one purchased level per technology per Economic Phase
- dice mode tracks bought dice separately and does not auto-increase the real tech level
- direct level setter remains available so users can resolve dice and then update actual levels manually

Important note:

- at that stage the local extracted rule text referenced the Research Chart but did not expose the chart values cleanly enough to encode them with confidence
- that is now superseded for the core spreadsheet-backed techs by the later `Spreadsheet Tech Chart Pass` below

## Spreadsheet Tech Chart Pass

The technology model now uses real chart values from the local spreadsheets instead of placeholder defaults.

Sources checked:

- `TrackingShip.xls`
- `Production.xls`

Confirmed chart values pulled in:

- `Ship Size`: 2=10, 3=15, 4=20, 5=25, 6=30
- `Move`: 2=20, 3=30, 4=40, 5=40, 6=40
- `Attack`: 1=20, 2=30, 3=40
- `Defense`: 1=20, 2=30, 3=40
- `Tactics`: 1=15, 2=20, 3=30
- `Ship Yard`: 2=20, 3=30
- `Terraforming`: 1=25
- `Exploration`: 1=15
- `Fighters`: 1=25, 2=30, 3=40
- `Point Def.`: 1=20, 2=25, 3=30
- `Cloaking`: 1=30, 2=40
- `Scanners`: 1=20, 2=30
- `Mines`: 1=20
- `Mine Sweep`: 1=10, 2=20

Also corrected to match the sheet:

- max levels for core techs were reduced where the app had been too generous
- `Ship Yard` naming was normalized so rule links and tech logic point at the same tech

Still manual / fallback:

- technologies not covered by those local sheets still allow manual cost entry
- `Advanced Con.` uses the extracted rulebook cost of `10 CP` per level from `38.1.1` to `38.1.3`

## Production Slimming Pass

The Production tab was trimmed back toward a spreadsheet workflow.

Implemented:

- narrower page padding
- tighter section cards and ledger sections
- smaller rule chips everywhere
- removed the big explanatory intro paragraph from the top of Production
- removed the extra context-prompt chip wall from `Worlds And Fleets`
- replaced the card-per-tech layout with a dense technology ledger

Technology UI now:

- shows mode, research left, and a tiny rules strip
- uses one row per tech
- shows:
  - name
  - current level
  - next cost or cost progression
  - bought count
  - buy / undo
  - direct rules button

This is closer to the production sheet and exposes more rows at once on-screen.

## Shell Slimming Pass

The top chrome was reduced again after real-device feedback.

Implemented:

- new slim resource bar used by the shell instead of the old banner-style top bar
- kept the rocket
- removed game name, turn label, and phase label from the top band
- removed the top-right `...` state menu so it no longer duplicates the Games workflow
- tightened page padding on Command, Production, Combat, Rules, and Games

Technology UI also now shows a clearer live research budget:

- `RP left` / `CP left`
- `RP spent` / `CP spent`
- buys reduce that counter immediately
