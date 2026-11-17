# flutter_tutorial_animated example

A notes screen that runs a four-step tutorial on start:

1. a plain step pointing at an app-bar action,
2. a step with an illustrative animation centred on a drag handle,
3. a step whose `beforeStep` scrolls its target into view,
4. a step at the bottom-right corner, where the bubble sits above the target.

The app is built on `material_ui`; its theme colours are passed to the
tutorial through `TutorialStyle`.

```bash
fvm flutter run
```
