/// What the dimmed background of a [Tutorial] does with taps.
enum TutorialBarrier {
  /// The whole background, the highlight included, takes taps, so the app
  /// below receives none while the tutorial is on screen.
  opaque,

  /// Taps inside the highlight reach the app below, so the user can do
  /// what the step describes; the rest of the background takes them.
  passThroughHighlight,

  /// Every tap outside the bubble reaches the app below. Use it for steps
  /// that point things out without stopping the app, e.g. in a game that
  /// keeps running.
  transparent,
}
