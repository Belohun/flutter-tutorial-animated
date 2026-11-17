## 0.1.0

* Initial release.
* `Tutorial` overlay that highlights widgets one step at a time, with an
  animated cut-out, pointer and description bubble.
* Per-step `beforeStep` callback (e.g. to scroll the target into view) and
  optional illustrative `animation`.
* `TutorialStyle` for colours, text styles, icons, timing and highlight shape;
  defaults follow the ambient `Theme`.
* `Tutorial.show` reports how the tutorial ended with a `TutorialResult`.
