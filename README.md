# flutter_tutorial_animated

An animated, step-by-step tutorial overlay for Flutter. Each step dims the
screen around a widget, points at it with a bubble holding a description, and
lets the user go back, forward or close. Moving between steps animates the
cut-out, the pointer and the bubble.

## Features

- Spotlights any widget by its `GlobalKey`, with an animated cut-out.
- Bubble placed below or above the target, whichever half of the screen it is
  in; the pointer stays on the target even next to the screen edges.
- `beforeStep` callback per step, awaited before the step is shown — scroll the
  target into view there.
- Optional per-step illustrative `animation` (a Lottie, an animated hand, ...)
  drawn over the target and never stealing taps.
- Waits for targets that are not laid out yet, with a timeout.
- `TutorialStyle` for colours, text styles, icons, timing and highlight shape;
  defaults follow your `Theme`.
- Tells you how it ended: completed, closed, or target not found.

## Getting started

```yaml
dependencies:
  flutter_tutorial_animated: ^0.1.0
```

The tutorial uses Material widgets, so it needs a `MaterialApp` (or an
`Overlay` and `MaterialLocalizations`) above it.

## Usage

Attach a `GlobalKey` to every widget you want to highlight:

```dart
final _searchKey = GlobalKey();
final _addKey = GlobalKey();

IconButton(key: _searchKey, icon: const Icon(Icons.search), onPressed: _search);
FloatingActionButton(key: _addKey, onPressed: _add, child: const Icon(Icons.add));
```

Then show the tutorial:

```dart
final result = await Tutorial(
  items: [
    TutorialItem(targetKey: _searchKey, description: 'Search your notes here.'),
    TutorialItem(targetKey: _addKey, description: 'Tap to add a new note.'),
  ],
).show(context);

if (result == TutorialResult.completed) {
  // Remember not to show it again.
}
```

Show it once the targets are laid out, e.g. from
`WidgetsBinding.instance.addPostFrameCallback`. Targets that are not laid out
yet are waited for, up to `Tutorial.targetTimeout`.

### Scrolling a target into view

```dart
TutorialItem(
  targetKey: _lastItemKey,
  description: 'Swipe an item to delete it.',
  beforeStep: () => Scrollable.ensureVisible(
    _lastItemKey.currentContext!,
    duration: const Duration(milliseconds: 300),
  ),
),
```

### Illustrating a gesture

```dart
TutorialItem(
  targetKey: _cardKey,
  description: 'Drag the card by its handle to reorder.',
  animation: Lottie.asset('assets/finger_down.json'),
  // Centre the animation on the handle rather than on the whole card.
  animationAnchorKey: _handleKey,
),
```

The animation is laid out in a square as tall as the target and never receives
taps.

### Styling

```dart
Tutorial(
  style: const TutorialStyle(
    overlayColor: Colors.black54,
    bubbleColor: Colors.white,
    descriptionTextStyle: TextStyle(fontSize: 16),
    animationDuration: Duration(milliseconds: 400),
    highlightRadius: Radius.circular(16),
  ),
  items: [...],
);
```

See [`example/`](example) for a complete app.

## License

MIT
