// Curated default-name pools sourced from across science fiction literature,
// film, television, anime, tabletop, and pulp serials. Used to give fleets,
// enemy fleets, and colonies a memorable default instead of "Fleet 3" or
// "Colony 7". Users can always rename via the inspector / production page.
//
// Sources span: Star Trek, Star Wars, Battlestar Galactica, Babylon 5,
// The Expanse, Halo, Mass Effect, Stargate, Firefly, Alien, 2001, Aliens,
// Hitchhiker's Guide, Iain Banks Culture, Niven Known Space, Heinlein,
// Asimov Foundation, Dune (Herbert), Hyperion (Simmons), Pern (McCaffrey),
// Vorkosigan (Bujold), Reynolds Revelation Space, Lem, Ann Leckie,
// Kim Stanley Robinson, Arthur C Clarke, Vance, Stapledon, Burroughs,
// Lensman (E.E. Smith), Ad Astra, Interstellar, The Martian, Sunshine,
// Cowboy Bebop, Macross, Gundam, Space Battleship Yamato, Knights of
// Sidonia, Doctor Who, Andromeda, Original BSG, Forbidden Planet,
// Last Starfighter, Mechwarrior, Warhammer 40k, Perry Rhodan,
// Commander Perkins, Flash Gordon, and a dash of weird mil-sf pulp.
//
// Names with a clear single canonical home are kept (e.g. "Enterprise"),
// but obviously unique character names are avoided in the fleet pool.

import 'dart:math';

/// Pool of 200 friendly fleet / ship names.
const List<String> kFleetNames = [
  // Star Trek
  'Enterprise', 'Voyager', 'Defiant', 'Excelsior', 'Reliant', 'Stargazer',
  'Constellation', 'Sovereign', 'Yamato', 'Hood', 'Phoenix', 'Intrepid',
  'Discovery', 'Shenzhou', 'Cerritos', 'Lexington', 'Yorktown', 'Republic',
  'Saratoga', 'Sutherland', 'Akira', 'Prometheus', 'Equinox', 'Kelvin',
  'Farragut', 'Crazy Horse', 'Bozeman', 'Pasteur', 'Hathaway', 'Bonchune',
  // Star Wars
  'Millennium Falcon', 'Tantive IV', 'Ghost', 'Razor Crest', 'Outrider',
  'Eclipse', 'Devastator', 'Chimaera', 'Lusankya', 'Mon Remonda', 'Liberator',
  'Defiance', 'Home One', 'Independence', 'Profundity', 'Resurgent',
  'Vigilance', 'Avenger', 'Thunderflare', 'Errant Venture',
  // Battlestar Galactica
  'Galactica', 'Pegasus', 'Atlantia', 'Columbia', 'Solaria', 'Acropolis',
  'Olympia', 'Triton', 'Valkyrie', 'Mercury',
  // Babylon 5
  'White Star', 'Excalibur', 'Agamemnon', 'Hyperion', 'Cortez', 'Churchill',
  'Pournelle', 'Heimdall', 'Roanoke', 'Schwarzkopf',
  // The Expanse
  'Rocinante', 'Canterbury', 'Donnager', 'Behemoth', 'Tachi', 'Razorback',
  'Anubis', 'Pella', 'Nauvoo', 'Agatha King',
  // Halo
  'Pillar of Autumn', 'Forward Unto Dawn', 'In Amber Clad', 'Infinity',
  'Truth and Reconciliation', 'Ascendant Justice', 'Iroquois', 'Spirit of Fire',
  'Heart of Midlothian', 'Long Time Coming',
  // Stargate
  'Daedalus', 'Odyssey', 'Sun Tzu', 'Apollo', 'Korolev', 'Hammond',
  'Achilles', 'Aurora', 'Tria', 'Orion',
  // Firefly
  'Serenity', 'Magellan', 'Dortmunder', 'Walden',
  // Alien franchise
  'Nostromo', 'Sulaco', 'Patna', 'Covenant', 'Prometheus II', 'Auriga',
  // 2001 / Clarke
  'Discovery One', 'Leonov', 'Goliath', 'Endeavour', 'Universe',
  // Andromeda
  'Andromeda Ascendant', 'Eureka Maru', 'Pax Magellanic',
  // Macross / Robotech
  'SDF-1', 'Megaroad', 'Macross Quarter', 'Battle 7',
  // Gundam UC
  'White Base', 'Argama', 'Ra Cailum', 'Nahel Argama',
  // Yamato / others
  'Yamato Maru', 'Andromeda II', 'Arizona', 'Bismarck',
  // Cowboy Bebop / Outlaw Star / Knights of Sidonia
  'Bebop', 'Swordfish II', 'Outlaw Star', 'Sidonia',
  // Iain Banks Culture (truncated where amusing)
  'Of Course I Still Love You', 'Just Read the Instructions',
  'Mistake Not...', 'Lasting Damage', 'So Much For Subtlety',
  'Determinist', 'Sleeper Service', 'Limiting Factor', 'Grey Area',
  'Killing Time', 'Honest Mistake', 'Frank Exchange of Views', 'No More Mr Nice Guy',
  // Niven Known Space
  'Long Shot', 'Lying Bastard', 'Slaver', 'Pak', 'Hindmost',
  // Heinlein
  'Lewis and Clark', 'Cygnus', 'Rolling Stone', 'Free Trader Beowulf',
  // Asimov Foundation
  'Bayta', 'Far Star', 'Trantorian',
  // Hyperion (Simmons)
  'Yggdrasill', 'Raphael', 'Hawking', 'Templar Tree', 'Nordholm',
  // Reynolds Revelation Space
  'Nostalgia for Infinity', 'Storm Bird', 'Zodiacal Light',
  // Hitchhiker's Guide
  'Heart of Gold', 'Bistromath', 'Vogon Constructor',
  // Star Trek extras + Lensman
  'Skylark', 'Britannia', 'Lensman', 'Civilization',
  // Interstellar / The Martian / Sunshine / Event Horizon
  'Endurance', 'Ranger', 'Hermes', 'Icarus II', 'Event Horizon',
  // Forbidden Planet / Last Starfighter / Lost in Space
  'C-57D', 'Gunstar', 'Jupiter 2',
  // Warhammer 40k
  'Phalanx', 'Macragge\'s Honour', 'Vulkan\'s Wrath', 'Wrath of Iron',
  'Sword of Truth', 'Spear of Russ', 'Iron Blood',
  // BattleTech
  'McKenna\'s Pride', 'Invisible Truth', 'Black Lion', 'Cameron',
  // Perry Rhodan / Commander Perkins
  'Stardust', 'Solar', 'Crest', 'Marco Polo', 'Drusus', 'Bassanio',
  'Phantastica', 'Pluto', 'Centurion',
  // Doctor Who
  'TARDIS', 'Valiant', 'Pyroviles',
  // Star Trek Klingon / Romulan flavor
  'Bortas', 'Kronos One', 'Negh\'Var', 'Rotarran', 'Vor\'cha',
  'IRW Decius', 'IRW Praetus', 'IRW Khazara',
  // Pulp / golden age
  'Skylark of Space', 'Triplanetary', 'Boskone', 'Tellurian',
  // Misc evocative
  'Ad Astra', 'Wayfarer', 'Dauntless', 'Indomitable', 'Vanguard',
  'Inflexible', 'Audacious', 'Resolute', 'Tenacious', 'Pioneer',
  'Wanderer', 'Trailblazer', 'Pathfinder', 'Vigil', 'Sentinel',
  'Guardian', 'Watchman', 'Stalwart', 'Steadfast', 'Lionheart',
  'Black Prince', 'Northern Light', 'Aurora Borealis',
];

/// Pool of 200 enemy / villain fleet names.
const List<String> kEnemyFleetNames = [
  // Star Trek antagonists
  'Reaper', 'Scimitar', 'Negh\'Var', 'Ravager', 'Enterprise-B',
  'Borg Cube', 'Locutus', 'Dominion', 'Jem\'Hadar Battlecruiser',
  'Cardassian Galor', 'Romulan Warbird', 'Klingon Bird-of-Prey',
  // Star Wars Empire
  'Executor', 'Devastator', 'Avenger', 'Eclipse', 'Sovereign', 'Vengeance',
  'Tyrant', 'Conqueror', 'Inquisitor', 'Imperialis', 'Star Destroyer',
  'Death\'s Head', 'Iron Fist', 'Immortal', 'Subjugator',
  // Mass Effect Reapers
  'Sovereign Prime', 'Harbinger', 'Nazara', 'Destiny Ascension',
  // Cylon (BSG)
  'Basestar', 'Resurrection Ship', 'Nemesis', 'Thunderclap',
  // Necron / 40k antagonists
  'World Engine', 'Tomb Ship', 'Cairn', 'Hammer of Sunset',
  // Halo Covenant
  'Solemn Penance', 'Ascendant Justice', 'Particular Justice',
  'Long Night of Solace', 'Shadow of Intent', 'Anodyne Spirit',
  'Bloodied Spirit', 'Unyielding Hierophant',
  // Banks Culture villains / outsiders
  'Ravager II', 'Excession', 'Iridium Sky',
  // Babylon 5 Shadows
  'Z\'ha\'dum', 'Shadow Battlecrab', 'Drakh', 'Dark Star',
  // Generic menacing
  'Annihilator', 'Eradicator', 'Marauder', 'Plunderer', 'Reaver',
  'Vulture', 'Carrion', 'Carrion Crow', 'Black Sun', 'Blackstar',
  'Nightshade', 'Nightfall', 'Doomsayer', 'Doomhammer', 'Skullcrusher',
  'Bonecrusher', 'Bloodfang', 'Bloodletter', 'Painbringer', 'Soulreaver',
  'Wraith', 'Specter', 'Phantasm', 'Banshee', 'Banshee\'s Wail',
  'Hexenbiest', 'Krakenfaust', 'Leviathan', 'Hydra', 'Cerberus',
  'Manticore', 'Chimera', 'Basilisk', 'Wyvern', 'Tiamat',
  'Apophis', 'Sutekh', 'Anubis', 'Ra\'s Wrath', 'Apep',
  'Hades', 'Tartarus', 'Erebus', 'Charon', 'Styx',
  'Acheron', 'Cocytus', 'Lethe', 'Phlegethon',
  'Nemesis Prime', 'Dies Irae', 'Mortis', 'Requiem', 'Dirge',
  // Niven Kzin
  'Slashclaw', 'Bloodclaw', 'Tailbiter', 'Kraach',
  // Old grimdark trope names
  'Grim Reaper', 'Ash to Ash', 'Cataclysm', 'Calamity', 'Apocalypse',
  'Ragnarok', 'Götterdämmerung', 'Twilight', 'Total Eclipse', 'Black Hole',
  'Singularity', 'Event Horizon', 'Oblivion', 'Void Hunter',
  'Star-Eater', 'World Killer', 'Sun Crusher', 'Planet Bane',
  // Perry Rhodan villains
  'Anti', 'Topsider', 'Posbi', 'Halut', 'Druuf', 'Maahks',
  'Blue Lord', 'Solar Wolf', 'Akon', 'Kemoauc',
  // Lensman
  'Boskonian', 'Eddorian', 'Kalonian', 'Ploorian', 'Onlonian',
  // Forbidden Planet / pulp
  'Krell', 'Morbius', 'Altair Spirit',
  // Alien / Predator
  'Xenomorph', 'Yautja', 'Big Chap', 'Engineer',
  // Doctor Who villain ships
  'Dalek Saucer', 'Cyber-Carrier', 'Sontaran Battleship', 'Movellan',
  'Sycorax', 'Macra', 'Krillitane',
  // Misc generic threat
  'Iron Heel', 'Ironclad', 'Steel Wind', 'Steelcrow', 'Razorback',
  'Razor\'s Edge', 'Cutthroat', 'Bloody Mary', 'Black Death',
  'Pestilence', 'Famine', 'War', 'Conquest', 'Hunger',
  'Greed', 'Wrath', 'Envy', 'Pride', 'Sloth',
  'Belial', 'Beelzebub', 'Asmodeus', 'Mammon', 'Leviathan II',
  'Abaddon', 'Lilith', 'Moloch', 'Baphomet',
  'Mordor', 'Barad-dûr', 'Saruman\'s Rod',
  // German pulp / Commander Perkins enemies
  'Tonnaer', 'Garmiani', 'Krelh',
  'Fenris', 'Hel', 'Niflheim', 'Surtr', 'Jormungandr',
  'Ymir', 'Loki\'s Spite', 'Mjolnir',
  // Final wave for round number
  'Black Fang', 'Shadowstrike', 'Iron Talon', 'Terror', 'Dread',
  'Overlord', 'Iron Tyrant', 'Despot', 'Suzerain', 'Throne of Skulls',
  'Court of the Worm', 'Crimson Tide', 'Crimson Star', 'Crimson Dawn',
  'Crimson Fleet', 'Bloodtide', 'Hellraiser', 'Hellfire', 'Helldiver',
  'Inferno', 'Pyre', 'Pyrelord', 'Wildfire', 'Burning Sun',
  'Doom\'s Edge', 'Edge of Night',
];

/// Pool of 200 colony / planet names.
const List<String> kPlanetNames = [
  // Dune
  'Arrakis', 'Caladan', 'Giedi Prime', 'Kaitain', 'Salusa Secundus', 'Ix',
  'Tleilax', 'Chapterhouse', 'Wallach IX', 'Junction',
  // Star Trek
  'Vulcan', 'Romulus', 'Qo\'noS', 'Bajor', 'Cardassia', 'Andoria', 'Tellar',
  'Risa', 'Cestus III', 'Kronos', 'Ferenginar', 'Trillius Prime',
  // Star Wars
  'Tatooine', 'Coruscant', 'Naboo', 'Hoth', 'Endor', 'Yavin', 'Dagobah',
  'Alderaan', 'Bespin', 'Kamino', 'Geonosis', 'Mustafar', 'Kashyyyk',
  'Mandalore', 'Jakku', 'Crait', 'Exegol', 'Felucia', 'Ryloth', 'Lothal',
  'Sullust', 'Corellia', 'Mon Cala', 'Onderon',
  // Asimov Foundation
  'Trantor', 'Terminus', 'Anacreon', 'Synnax', 'Helicon', 'Smyrno', 'Korell',
  'Solaria', 'Aurora',
  // Hyperion (Simmons)
  'Hyperion', 'Tau Ceti Center', 'Lusus', 'Pacem', 'God\'s Grove',
  'Renaissance Vector', 'Heaven\'s Gate', 'Maui-Covenant',
  // Banks Culture
  'Vavatch', 'Eä', 'Schar\'s World', 'Phage Rock', 'Vincennes',
  // Niven Known Space
  'Ringworld', 'Wunderland', 'Plateau', 'We Made It', 'Down', 'Jinx',
  'Home', 'Margrave',
  // Pern
  'Pern',
  // Vorkosigan
  'Barrayar', 'Beta Colony', 'Komarr', 'Sergyar', 'Cetaganda', 'Athos',
  'Jackson\'s Whole',
  // Mass Effect
  'Eden Prime', 'Feros', 'Noveria', 'Virmire', 'Tuchanka', 'Palaven',
  'Sur\'Kesh', 'Thessia', 'Khar\'shan', 'Rannoch', 'Illium',
  // Halo
  'Reach', 'Harvest', 'Sanghelios', 'Onyx', 'Installation 04',
  'Kholo', 'Madrigal',
  // Avatar
  'Pandora',
  // Firefly
  'Persephone', 'Ariel', 'Beaumonde', 'Whitefall', 'Sihnon', 'Boros',
  'Beylix', 'Hera', 'Miranda',
  // Babylon 5
  'Centauri Prime', 'Minbar', 'Narn', 'Z\'ha\'dum', 'Brakir', 'Markab',
  // The Expanse
  'Ceres', 'Pallas', 'Ganymede', 'Europa', 'Io', 'Titan', 'Enceladus',
  'Phoebe', 'Ilus', 'Eros', 'Tycho',
  // Stargate
  'Abydos', 'Chulak', 'Dakara', 'Tollan', 'Langara', 'Edora', 'Latona',
  'Cimmeria',
  // Doctor Who
  'Gallifrey', 'Skaro', 'Mondas', 'Telos', 'Sontar', 'Trenzalore', 'Karn',
  // BSG colonies
  'Caprica', 'Tauron', 'Aerilon', 'Sagittaron', 'Picon', 'Gemenon', 'Leonis',
  'Libran', 'Virgon', 'Scorpia', 'Aquaria', 'Canceron', 'Kobol', 'New Caprica',
  // Lensman
  'Tellus', 'Klovia', 'Velantia', 'Norlamin', 'Trenco', 'Eddore', 'Arisia',
  'Nevia', 'Lonabar',
  // Perry Rhodan
  'Arkon', 'Larsa', 'Wanderer', 'Plophos', 'Topsid', 'Trakar', 'Gatas',
  'Thantur-Lok',
  // Mechwarrior / BattleTech
  'Solaris VII', 'Tharkad', 'Atreus', 'Sian', 'Luthien', 'New Avalon',
  'New Syrtis', 'Galatea', 'Skye', 'Tikonov',
  // Warhammer 40k
  'Cadia', 'Armageddon', 'Macragge', 'Fenris', 'Catachan', 'Krieg',
  'Valhalla', 'Tallarn', 'Necromunda', 'Holy Terra', 'Ultramar',
  'Tanith', 'Vostroya', 'Mordian', 'Prospero', 'Caliban', 'Baal', 'Nocturne',
  // Reynolds Revelation Space
  'Yellowstone', 'Resurgam', 'Ararat', 'Hela', 'Sky\'s Edge',
  // Bujold extras / Culture extras / Vance
  'Quaddiespace', 'Vega Station', 'Tschai', 'Big Planet',
  // Burroughs
  'Barsoom', 'Amtor', 'Pellucidar',
  // Wells / Verne / KSR
  'Mars Reborn', 'Aurora II', 'Boreas',
  // Lem / Strugatsky
  'Solaris', 'Eden', 'Pirx',
  // Misc evocative coined names
  'Terra Nova', 'Kepler', 'Proxima', 'Avalon', 'Arcadia', 'Elysium',
  'Eden Reach', 'New Eden', 'Atlantis', 'Asgard', 'Olympus', 'Tartarus',
  'Erewhon', 'Utopia', 'Lemuria', 'Hyperborea', 'Thule', 'Camelot',
  'Albion', 'Hesperia', 'Ophir', 'Ophiuchus', 'Lyra', 'Cygnus',
  'Eridanus', 'Vega', 'Altair', 'Sirius', 'Rigel', 'Antares',
  'Betelgeuse', 'Aldebaran', 'Polaris', 'Arcturus', 'Capella',
  'Procyon', 'Canopus', 'Deneb', 'Spica', 'Achernar', 'Fomalhaut',
  'Bellatrix', 'Mira', 'Sadalsuud', 'Almach', 'Mirfak',
  'Diphda', 'Algol', 'Mintaka', 'Alnitak', 'Saiph',
  'New Geneva', 'New Bombay', 'New Detroit', 'New Hong Kong',
  'New Stockholm', 'Far Reach', 'Last Hope', 'Outpost Theta',
  'Orion\'s Edge', 'Boreal', 'Frostfall', 'Embergate', 'Stormhaven',
  'Halcyon', 'Halibrand',
];

/// Picks the first unused name from `pool` given the set of `taken` names.
/// Falls back to a randomized "{pool first} N" pattern when the entire pool
/// is exhausted (very unlikely with 200-entry pools, but defensive).
/// Pool of 100+ campaign / save-game names — evocative sci-fi mission and
/// chronicle titles. Used as the default name for a freshly created game.
const List<String> kGameNames = [
  'The Long Night', 'Rise of the Imperium', 'Echoes of Arrakis',
  'Ashes of Cadia', 'The Foundation Cycle', 'Reach for the Stars',
  'Twilight of the Old Republic', 'A Galaxy Divided', 'The Last Lensman',
  'Children of Trantor', 'Wake of the Endurance', 'The Mote in God\'s Eye',
  'Ringworld\'s Last Stand', 'Pern\'s First Pass', 'Banks of the Culture',
  'Hyperion\'s Tide', 'Shards of Coruscant', 'Tears of Pandora',
  'Caprica Burning', 'The Cylon Verdict', 'Dune Messiah Reborn',
  'House Atreides', 'The Spice Must Flow', 'Honor of the Mentat',
  'Path of the Gom Jabbar', 'Whispers from Z\'ha\'dum',
  'Shadow War', 'Vorlon Ascendant', 'The Coming of the Shadows',
  'Babel\'s Last Hope', 'Daedalus Rising', 'Apollo\'s Reach',
  'The Long Patrol', 'Frontier Drift', 'Outpost on Tau Ceti',
  'Beyond the Veil', 'The Heliopause Run', 'Ad Astra Per Aspera',
  'Cold Equations', 'Starman\'s Gambit', 'Solar Wind',
  'Galactic Pioneers', 'Empire of the Sun', 'Crown of Stars',
  'The Last Earth', 'Terra Reborn', 'Sol Rising',
  'Drake\'s Equation', 'Fermi\'s Silence', 'The Great Filter',
  'Kardashev Ascension', 'Type II Dawn', 'Dyson\'s Rim',
  'The Mind Killer', 'Lensman\'s Last Charge', 'Boskonian Rebellion',
  'Norlamin Council', 'Arisia\'s Watch', 'The Eddorian Threat',
  'Stardust Trail', 'Pulsar Run', 'Beacon at Rigel',
  'Vega\'s Daughters', 'Antares Burning', 'Sirius Conspiracy',
  'The Andromeda Gambit', 'Magellanic Crossing', 'Bridge to Tarn-Vedra',
  'The Long Voyage Home', 'Forty Thousand in Gehenna',
  'Mote in the Eye', 'Footfall', 'Lucifer\'s Hammer',
  'The Forever War', 'Ender\'s Shadow', 'Speaker for the Dead',
  'Hyperion\'s Cantos', 'The Fall of Hyperion', 'Endymion\'s Promise',
  'Revelation Space', 'Chasm City Nights', 'Absolution Gap',
  'Pushing Ice', 'House of Suns', 'Century Rain',
  'Ancillary Justice', 'Ancillary Sword', 'Empire of the Radch',
  'The Vorkosigan Saga', 'Komarr Rising', 'Cetaganda\'s Shame',
  'Sergyar Frontier', 'Beta Colony Diaries', 'Athos Conclave',
  'Quaddiespace', 'Memory of Light', 'Wheel of Conflict',
  'Ringbearer\'s Last Hope', 'The Long Earth', 'The Long Mars',
  'The Long Cosmos', 'Mars Trilogy', 'Red Mars Rising',
  'Green Mars Bloom', 'Blue Mars Reborn', 'Aurora\'s Voyage',
  '2312', 'New York 2140', 'The Ministry for the Future',
  'Starfish Tide', 'Behemoth Awakens', 'Maelstrom\'s Edge',
  'Project Hail Mary', 'The Martian Chronicles', 'Bradbury\'s Children',
  'Childhood\'s End', 'Rendezvous with Rama', 'The Songs of Distant Earth',
  'A Deepness in the Sky', 'A Fire Upon the Deep', 'The Children of the Sky',
  'Old Man\'s War', 'The Last Colony', 'The Ghost Brigades',
  'Redshirts', 'Lock In', 'Head On',
  'Leviathan Wakes', 'Caliban\'s War', 'Abaddon\'s Gate',
  'Cibola Burn', 'Nemesis Games', 'Babylon\'s Ashes',
  'Persepolis Rising', 'Tiamat\'s Wrath', 'Leviathan Falls',
  'The Expanse Continues', 'Belter Uprising', 'Free Navy',
  'The Halo Conflict', 'Forerunner Saga', 'Master Chief\'s Watch',
  'Spartan Initiative', 'ONI Files', 'The Cole Protocol',
  'Reach Falls', 'Harvest Wakes', 'The Fall of Reach',
  'Mass Effect Origins', 'The Reaper Cycle', 'Saren\'s Conspiracy',
  'Crucible Project', 'Citadel\'s Last Stand', 'Quarian Homecoming',
  'Geth Consensus', 'Krogan Rebellion', 'Rachni Wars',
  'Stargate Pioneers', 'The Goa\'uld Conflict', 'Asgard Vigil',
  'Wraith Hive', 'Atlantis Expedition', 'Replicator Outbreak',
  'Ori Crusade', 'Genesis Code', 'The Doctor Returns',
  'Time War', 'Gallifreyan Twilight', 'Skaro\'s Last Dalek',
  'Cyberus Rising', 'Sontaran Threat', 'Movellan Drift',
  'Space Battleship Yamato', 'Macross Frontier', 'Robotech Defenders',
  'Gundam One Year War', 'Char\'s Counterattack', 'Universal Century',
  'Cowboy Bounty', 'Outlaw Star Run', 'Knights of Sidonia',
  'Perry Rhodan Cycle', 'Atlan\'s Quest', 'Stardust\'s Path',
  'Commander Perkins', 'Phantastica Beckons', 'Flash Gordon\'s Crusade',
  'Ming the Merciless', 'The Lensmen Rise',
  'Skylark of Valeron', 'Triplanetary', 'Galactic Patrol',
  'Children of the Lens', 'First Lensman',
  'Heinlein\'s Future History', 'The Past Through Tomorrow',
  'Stranger in a Strange Land', 'Starship Troopers',
  'The Moon Is a Harsh Mistress', 'Time Enough for Love',
  'Niven\'s Known Space', 'Tales of the Pak', 'Kzin Wars',
  'Man-Kzin Conflict', 'Slaver Stasis', 'Outsider Trade',
];

/// Pool of 100+ alien race / NPC empire names. Used as defaults for
/// alien players (was "Alien 1", "Alien 2"). Sourced from sci-fi
/// antagonist factions, mysterious civilizations, and pulp menaces.
const List<String> kAlienNames = [
  'Borg Collective', 'Vogons', 'Klingon Empire', 'Romulan Star Empire',
  'Cardassian Union', 'Dominion', 'Breen Confederacy', 'Tholians',
  'Sheliak Corporate', 'Hirogen Hunters', 'Kazon Order', 'Vidiians',
  'Xindi', 'Suliban Cabal', 'Gorn Hegemony', 'Tzenkethi Coalition',
  'Galactic Empire', 'Sith Eternal', 'Trade Federation',
  'Mandalorian Clans', 'Hutt Cartel', 'Yuuzhan Vong', 'Chiss Ascendancy',
  'Imperial Remnant', 'Black Sun', 'Crimson Dawn',
  'Cylon Centurions', 'Final Five', 'Twelve Colonies',
  'Shadows of Z\'ha\'dum', 'Vorlon Empire', 'Drakh', 'Centauri Republic',
  'Narn Regime', 'Minbari Federation', 'Markab Faith', 'Drazi Freehold',
  'Pak\'ma\'ra', 'Ba\'ku', 'Son\'a Collective',
  'Reapers', 'Collectors', 'Geth Consensus', 'Quarian Migrant Fleet',
  'Krogan Clans', 'Turian Hierarchy', 'Asari Republics', 'Salarian Union',
  'Batarian Hegemony', 'Volus Protectorate', 'Elcor Dignity', 'Hanar Compact',
  'Drell Refugees', 'Vorcha Packs', 'Yahg Dominion', 'Rachni Queen',
  'Covenant Loyalists', 'Sangheili Arbiter', 'Jiralhanae Brutes',
  'Kig-Yar Pirates', 'Unggoy Rebellion', 'Mgalekgolo Bond',
  'Forerunner Echo', 'Flood Gravemind', 'Prometheans',
  'Goa\'uld System Lords', 'Anubis Reborn', 'Apophis Resurrected',
  'Ra\'s Heralds', 'Ori Priors', 'Wraith Hive', 'Asuran Replicators',
  'Genii Conspiracy', 'Aschen Confederation', 'Kull Warriors',
  'Daleks', 'Cybermen', 'Sontaran Empire', 'Zygon Inquisition',
  'Silurian Awakening', 'Ice Warriors', 'Macra Hive', 'Krillitane Flock',
  'Sycorax Raiders', 'Slitheen Family', 'Weeping Angels', 'The Silence',
  'Kzinti Patriarchy', 'Puppeteer Concordance', 'Outsiders', 'Pak Protectors',
  'Slaver Empire', 'Tnuctipun', 'Bandersnatchi',
  'Eddorians', 'Boskonians', 'Onlonian Cartel', 'Kalonians',
  'Ploorians', 'Velantian Defenders',
  'Tau Empire', 'Tyranid Hive Fleet', 'Necron Dynasty', 'Ork Waaagh!',
  'Eldar Craftworld', 'Dark Eldar Kabals', 'Genestealer Cult',
  'Chaos Black Legion', 'Word Bearers', 'Death Guard', 'Thousand Sons',
  'Emperor\'s Children', 'World Eaters',
  'Topsider Hierarchy', 'Posbi Collective', 'Halut Concord',
  'Druuf Constructors', 'Maahks Engineers', 'Akon Council',
  'Antis', 'Solar Wolves', 'Blue Lords',
  'Krell Survivors', 'Yautja Hunters', 'Engineers of LV-426',
  'Xenomorph Hive', 'Replicator Swarm',
  'Andromedan Initiative', 'Magog Worldship', 'Nietzschean Pride',
  'Vedrans Lost', 'Nightsiders', 'Perseids',
  'Tonnaer Marauders', 'Garmiani Clan', 'Krelh Consortium',
  'Reaver Pack', 'Blue Sun Corporation', 'Alliance Parliament',
  'Tleilaxu Masters', 'Bene Gesserit', 'Ix Confederacy',
  'Spacing Guild', 'Honored Matres', 'Sardaukar Legion',
  'Fish Speakers', 'Fremen Council',
  'Korlivilar', 'Zentraedi Armada', 'Meltrandi Fleet',
  'Invid Regent', 'Robotech Masters', 'Disciples of Zor',
];

String pickUnusedName(List<String> pool, Set<String> taken, {String? fallbackPrefix}) {
  for (final name in pool) {
    if (!taken.contains(name)) return name;
  }
  // Pool exhausted: append a numeric suffix to a random pool entry.
  final rng = Random();
  final base = fallbackPrefix ?? pool[rng.nextInt(pool.length)];
  int n = 2;
  while (taken.contains('$base $n')) {
    n++;
  }
  return '$base $n';
}
