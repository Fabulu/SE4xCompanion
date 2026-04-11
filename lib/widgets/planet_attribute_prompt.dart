// Planet Attribute prompt (PP01 Phase 4).
//
// Asked after the player colonizes a new world, to offer attaching a
// Planet Attribute card. Returns one of:
//   - PlanetAttributePromptResult.random — caller should auto-pick
//   - PlanetAttributePromptResult.pick — caller should open the draw
//     dialog filtered to Planet Attributes
//   - PlanetAttributePromptResult.skip — caller should do nothing
//   - null — dialog dismissed / cancelled (treat as skip)

import 'package:flutter/material.dart';

enum PlanetAttributePromptResult { random, pick, skip }

Future<PlanetAttributePromptResult?> showPlanetAttributePrompt(
  BuildContext context, {
  required String worldName,
}) {
  return showDialog<PlanetAttributePromptResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Planet Attribute?'),
      content: Text(
        'Draw a Planet Attribute card for "$worldName"?\n\n'
        'Per RAW, each newly-colonized world may draw an attribute card. '
        'You can pick one manually, roll random, or skip.',
        style: const TextStyle(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(ctx).pop(PlanetAttributePromptResult.skip),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(ctx).pop(PlanetAttributePromptResult.pick),
          child: const Text('Pick'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(PlanetAttributePromptResult.random),
          child: const Text('Random'),
        ),
      ],
    ),
  );
}
