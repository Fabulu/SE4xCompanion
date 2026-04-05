# Contributing to SE4X Companion

Thanks for your interest! This project is an unofficial, fan-made companion app for Space Empires 4X. Contributions are welcome.

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Please include:

- Device OS + version
- App version (see Settings → About)
- Steps to reproduce
- Expected vs actual behavior
- Game context (which expansion, turn number, scenario)
- Screenshots where relevant

## Proposing Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md). Reference rulebook **section numbers** (not verbatim prose — copyright concern). Note which expansion(s) the feature touches and describe the intended workflow impact.

## Development Setup

```bash
git clone https://github.com/Fabulu/SE4xCompanion.git
cd SE4xCompanion
flutter pub get
flutter analyze   # must be clean
flutter test      # must pass
flutter run
```

Requires Flutter 3.x, Dart SDK ^3.11.1.

## Code Style

- Follow existing patterns in `lib/widgets/` and `lib/pages/`.
- `flutter analyze` must stay clean — no new warnings.
- Match the existing test patterns in `test/` — `group()` / `test()` / `testWidgets()`.
- Prefer small, focused widgets and pure functions where possible.
- JSON serialization: add new fields with default values in `fromJson` for backward compat.

## Testing

- Add tests for new models, services, and non-trivial widgets.
- Golden tests are welcome where visual stability matters.
- All tests must pass before merge.

## Pull Request Process

1. Fork the repo and create a branch off `master`.
2. Keep commits focused — one logical change per commit where possible.
3. Ensure `flutter analyze` is clean and `flutter test` passes.
4. Include screenshots for UI changes.
5. Fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md).
6. Reference any related issues with `Fixes #123` or `Closes #123`.

CI will automatically run `flutter analyze` and `flutter test`. PRs must be green before merge.

## Licensing

- No CLA required.
- Contributors retain copyright on their contributions.
- All contributions are licensed under the project's **MIT License** (see [LICENSE](LICENSE)).

## Commit Message Convention

Imperative mood summary line (≤72 chars), optional body with rationale:

```
Fix hex map layout for 5-player pentagonal board

The axial-skew x-formula was shearing the pentagon. Replaced with
row-offset shift matching measured per-row startCols from SE4xMap5p.png.
```

## Out of Scope

- **No rulebook prose contributions.** Rule section IDs and brief paraphrases are fine; verbatim copy-paste is not. Respect GMT's copyright.
- **No GMT artwork** (board tiles, ship art, logos).
- **No scans of physical components.**

## Questions?

Open a [discussion](https://github.com/Fabulu/SE4xCompanion/discussions) or email the maintainer (see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for contact).
