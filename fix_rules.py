#!/usr/bin/env python3
"""Fix rules_data.dart: rejoin hyphenated words, remove mid-sentence linebreaks, fix contaminated sections."""

import re

with open('lib/data/rules_data.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We need to find all body: ''' ... ''' blocks and process them
# Strategy: find each body string and process it

def fix_body(text):
    """Fix linebreaks and hyphenated words in a body string."""
    # 1. Rejoin hyphenated words split across lines
    text = re.sub(r'(\w)-\n(\w)', r'\1\2', text)
    # 2. Replace single newlines (not double) with space
    text = re.sub(r'(?<!\n)\n(?!\n)', ' ', text)
    # 3. Clean up multiple spaces
    text = re.sub(r'  +', ' ', text)
    return text

# Find all body: ''' ... ''' blocks
# Pattern: body: '''\n ... '''
# We need to be careful with the triple-quote delimiter

parts = []
pos = 0
body_pattern = re.compile(r"body: '''")

while pos < len(content):
    match = body_pattern.search(content, pos)
    if not match:
        parts.append(content[pos:])
        break

    # Add everything before this body
    parts.append(content[pos:match.end()])

    # Find the closing '''
    body_start = match.end()
    # Find ''' that closes this body - it should be on its own or followed by comma/etc
    close_idx = content.find("'''", body_start)
    if close_idx == -1:
        # No closing found, just append rest
        parts.append(content[body_start:])
        break

    body_text = content[body_start:close_idx]

    # Fix the body text
    fixed = fix_body(body_text)

    parts.append(fixed)
    parts.append("'''")
    pos = close_idx + 3

content = ''.join(parts)

# Now fix contaminated sections manually

# 1. Section 9.3 - remove 9.8 exploration content
# The body should end after describing Tactics technology
old_93 = """body: '''
This technology affects which ships fire first in combat when they have the same Weapon Class (5.2). This abstractly represents not only the tactical training of a player's units, but also certain aspects of te The ship is also allowed to move normally in that Movement Phase (and may explore a different hex in the usual fashion, as per 6.1). A ship that uses Exploration 1 technology is not revealed. Exploration technology cannot be used on a hex that has a Doomsday Machine or Alien Player fleet (SSB 4.0) in it. PLAY NOTE: This means that a ship equipped with Exploration 1 technology can explore 2 hexes each turn (one with Exploration technology and one by moving into the hex). An advanced version of this technology (Reaction Movement, 35.0) is available as an optional rule.'''"""
new_93 = """body: '''
This technology affects which ships fire first in combat when they have the same Weapon Class (5.2). This abstractly represents not only the tactical training of a player's units, but also certain aspects of technology.'''"""
content = content.replace(old_93, new_93)

# 2. Section 5.1.5 - trim to just repeat combat text
old_515 = """body: '''
If both the attacker and defender still have units in the hex after a round of combat, perform another round of combat starting w Important: The Attack and Defense technology modification may not normally exceed a unit's Hull Size (9.2).'''"""
new_515 = """body: '''
If both the attacker and defender still have units in the hex after a round of combat, perform another round of combat starting with step 5.1.1.'''"""
content = content.replace(old_515, new_515)

# 3. Section 19.3 - remove scrapping content from 19.5
old_193 = """body: '''
A ship captured by a boarding party immediately becomes controlled by the capturing player. A captured ship has the following properties: ' May not attack or retreat in the first full round immediately following capture (the boarding parties are in the process of gaining complete control of the ship). ' Does not count for Combat Screening (5.7) or Fleet Size bonus (5.1.3) on the round after they are captured. ' May be fired upon, screened, and may be recaptured. ' May attack and retreat normally after the first round, postcapture. If playing with Ship Experience (37.0 EXAMPLE: A player with Movement 1, Attack 2, Defense 1, and Tactics 1 captures a ship that has Movement 3, Attack 2, Defense 2, and Tactics 0. Upon scrapping the ship, the player gains Movement 2 and Defense 2 technology. If the player had another ship just like this one and scrapped it also, they would immediately gain Move 3 technology. The player could then choose to use CP to purchase Move 4 technology. The following restrictions apply to Scrapping technology: ' Scrapping a Carrier can only yield up to Fighter technology level 1, regardless of the level of Fighter technology the other player possessed. ' Ground Combat technology cannot be gained by scrapping a Transport (21.1). " Security Forces (20.0) and Military Academies (37.2) " both of which are not shown on the Ship Technology Sheet -- cannot be gained by capturing a ship. ' Any technology gained is limited to what is present on the ship being scrapped. ' In a game with more than two players and no teams, players cannot gain technology by scrapping captured ships. This is to prevent gamey tactics and/or collusion between players to advance their technology levels. PLAY NOTE: Ship Size technology can be gained by this method.'''"""
new_193 = """body: '''
A ship captured by a boarding party immediately becomes controlled by the capturing player. A captured ship has the following properties: ' May not attack or retreat in the first full round immediately following capture (the boarding parties are in the process of gaining complete control of the ship). ' Does not count for Combat Screening (5.7) or Fleet Size bonus (5.1.3) on the round after they are captured. ' May be fired upon, screened, and may be recaptured. ' May attack and retreat normally after the first round, post-capture.'''"""
content = content.replace(old_193, new_193)

# 4. Section 21.1.1 - trim ground unit properties
old_2111 = """body: '''
At the start of game, all players have Ground Combat 1, allowing them to build Transports and Infantry. Transports are used to carry Ground Units and Fighters (15.2). They may also be used to transport Dilithium Crystals (see the Deep Space Planet Attributes) and Logistic Points (36.5) if using those rules. Transports do not need to stop to pick up or drop off Ground Units or Fighters; they can pick them up while passing a planet in a similar way to a CV picking ' Require no maintenance cost. ' May not be placed on an uncolonized planet. ' Provide a defensive benefit against bombardment (21.6) and may not be hit by bombardment (21.7.4). ' Ground Units play no part in space combat. Whether on a Colony or on a Transport, they never shoot at ships, and they may never be shot at by ships. -- Are eliminated if not on a Colony or if in excess of Transport capacity.'''"""
new_2111 = """body: '''
At the start of game, all players have Ground Combat 1, allowing them to build Transports and Infantry. Transports are used to carry Ground Units and Fighters (15.2). They may also be used to transport Dilithium Crystals (see the Deep Space Planet Attributes) and Logistic Points (36.5) if using those rules. Transports do not need to stop to pick up or drop off Ground Units or Fighters; they can pick them up while passing a planet in a similar way to a CV picking up Fighters.'''"""
content = content.replace(old_2111, new_2111)

# 5. Section 21.11 - remove colony capture text from 21.13
old_2111b = """body: '''
Require Ground Combat 3. Grav Armor has a special ability beyond its normal attack. At the start of each round of combat, for every Grav Armor unit a player has over the amount that is ever flipped back to the Colony Ship side.) It will grow to 1 CP in the following Economic Phase. In the rare case where a Colony with only a Colony Ship would be captured, replace the Colony Ship with one of the capturing player's. The captured Colony is then treated like any of the capturing player's Colonies. It will provide income and grow, Shipyards may be built, Militia will be produced when attacked, etc. Any Minerals (6.7) and Space Wrecks (6.8) that are on the Colony when it is captured are destroyed with no benefit.'''"""
new_2111b = """body: '''
Require Ground Combat 3. Grav Armor has a special ability beyond its normal attack. At the start of each round of combat, for every Grav Armor unit a player has over the amount that the opponent has, one enemy ground unit is automatically eliminated before combat begins.'''"""
content = content.replace(old_2111b, new_2111b)

# 6. Section 40.2.1 - remove Anti-Replicator text
old_4021 = """body: '''
All Replicator ships have Move 1 technology unless a higher level is purchased (40.6.3). Replicators automatically gain an extra level of Move technology during Economic Phase 8 and Economic Phase 16 at no cost. This is indicated on t Anti-Replicator Tech on the same bombardment. A Transport can be equipped with Anti-Replicator Technology and still carry 6 Ground Units and/or Fighters. The Replicator Homeworld is treated the same as a Replicator Colony for all rules governing growth, blockade, bombardment, and destruction.'''"""
new_4021 = """body: '''
All Replicator ships have Move 1 technology unless a higher level is purchased (40.6.3). Replicators automatically gain an extra level of Move technology during Economic Phase 8 and Economic Phase 16 at no cost. This is indicated on the Replicator Technology Sheet.'''"""
content = content.replace(old_4021, new_4021)

# 7. Section 9.9.1 - fix truncated title
old_991_title = "title: 'Fast 1 (formerly called Fast Battlecruisers or Fast',"
new_991_title = "title: 'Fast 1 (formerly called Fast Battlecruisers or Fast BC)',"
content = content.replace(old_991_title, new_991_title)

# Fix 9.9.1 body - remove "BC): " from start
old_991_body = """body: '''
BC): Allows Battlecruisers"""
new_991_body = """body: '''
Allows Battlecruisers"""
content = content.replace(old_991_body, new_991_body)

# 8. Section 2.6 - near-empty, add note
old_26 = """body: '''
Colony'''"""
new_26 = """body: '''
Colony Ships, Decoys, and Bases are non-group units that are placed individually on the map (refer to rulebook for full details).'''"""
content = content.replace(old_26, new_26)

with open('lib/data/rules_data.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
