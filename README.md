# flutter_tutorial_animated

An animated, step-by-step tutorial overlay for Flutter. Each step dims the
screen around a widget, points at it with a bubble holding a description, and
lets the user go back, forward or close. Moving between steps animates the
cut-out, the pointer and the bubble.

## Features

- Spotlights any widget by its `GlobalKey`, or any area of the screen (a
  sprite in a game, a region of a canvas) through a callback that it follows
  as it moves.
- Bubble placed below or above the target, whichever half of the screen it is
  in; the pointer stays on the target even next to the screen edges.
- `beforeStep` callback per step, awaited before the step is shown — scroll the
  target into view there.
- Optional per-step illustrative `animation` (a Lottie, an animated hand, ...)
  drawn over the target and never stealing taps.
- Waits for targets that are not laid out yet, with a timeout.
- `TutorialStyle` for colours, text styles, icons, timing and highlight shape,
  or builders that replace the bubble and the pointer with your own.
- Barriers that let taps through the highlight, or everywhere, so the user
  can do what a step describes.
- Steps moved on from code, for tutorials that wait for the user to act, or
  by a touch on the highlight.
- Tells you how it ended: completed, closed, or target not found.

## Getting started

```yaml
dependencies:
  flutter_tutorial_animated: ^0.3.0
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

### Your own bubble and pointer

Replace the bubble with anything that matches your app. It is given the
width the layout allows and sizes its own height; `TutorialBubble` says
where the pointer meets it and carries the step's callbacks.

```dart
Tutorial(
  style: TutorialStyle(
    bubbleMaxWidth: 280,
    pointerSize: const Size(22, 14),
    pointerOverlap: 4,
    pointerBuilder: (context, direction) => CustomPaint(
      painter: MyTailPainter(pointsUp: direction == AxisDirection.up),
    ),
    bubbleBuilder: (context, bubble) => MyCard(
      text: bubble.description,
      onNext: bubble.isLast ? null : bubble.next,
      onClose: bubble.close,
    ),
  ),
  items: [...],
);
```

Extend `TutorialItem` to give your bubble more than a description, such as
a title, and read it back from `bubble.item`.

### Targets that are not widgets

`targetRect` reports the area to highlight in global coordinates, or `null`
while it is off screen. It is read on every frame of the step, so the
highlight follows a target that moves, such as a sprite in a game:

```dart
TutorialItem(
  description: 'Repair the ruin.',
  targetRect: () => game.screenRectOf(ruin),
),
```

### Letting the user act

By default the dimmed background takes every tap. `TutorialBarrier` changes
that for the whole tutorial or for one step:

- `passThroughHighlight`: taps inside the highlight reach the app.
- `transparent`: every tap outside the bubble reaches the app.

Pair it with `Tutorial.start`, which returns a `TutorialSession`, to move on
once the user has done what the step asks:

```dart
final session = Tutorial(
  barrier: TutorialBarrier.passThroughHighlight,
  items: [TutorialItem(targetKey: _buildKey, description: 'Build a tower.')],
).start(context);

// Later, when the tower is built:
session.next();
```

Set `nextOnTargetTouch` on a step to move on as soon as the user touches
its highlight, a tap or the start of a drag, so the bubble is out of the way
while they act. With a barrier that lets the touch through, the app gets it
too:

```dart
TutorialItem(
  targetKey: _towerCardKey,
  description: 'Drag a tower onto the map.',
  barrier: TutorialBarrier.passThroughHighlight,
  nextOnTargetTouch: true,
),
```

See [`example/`](example) for a complete app.

## License

MIT
