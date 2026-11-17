## 0.2.0

* `TutorialStyle.bubbleBuilder` builds the bubble in place of the default
  one, from a `TutorialBubble` (the step, where the pointer meets the bubble,
  and next / previous / close callbacks), so the bubble can match an app's
  own look.
* `TutorialStyle.pointerBuilder` and `pointerSize` replace the default
  triangle; `pointerOverlap` tucks it under the bubble's edge.
* `TutorialStyle.bubbleMaxWidth` keeps the bubble narrower than the screen,
  centred on the pointer.
* `TutorialItem.targetRect` highlights an area that is not a widget, such as
  a sprite in a game, and follows it while it moves. `targetKey` is now
  optional; give a step exactly one of the two.
* `TutorialBarrier` (on `Tutorial` and per `TutorialItem`) lets taps through
  the highlight, or everywhere but the bubble, so the user can do what a step
  describes while it is shown.
* `Tutorial.start` returns a `TutorialSession` that moves the tutorial on or
  finishes it from code, for steps the app ends when the user has done them.

## 0.1.0

* Initial release.
* `Tutorial` overlay that highlights widgets one step at a time, with an
  animated cut-out, pointer and description bubble.
* Per-step `beforeStep` callback (e.g. to scroll the target into view) and
  optional illustrative `animation`.
* `TutorialStyle` for colours, text styles, icons, timing and highlight shape;
  defaults follow the ambient `Theme`.
* `Tutorial.show` reports how the tutorial ended with a `TutorialResult`.
