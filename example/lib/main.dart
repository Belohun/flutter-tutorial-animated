import 'package:flutter_tutorial_animated/flutter_tutorial_animated.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_tutorial_animated',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const _noteCount = 30;
  static const _scrolledNote = 24;

  final _searchKey = GlobalKey(debugLabel: 'search');
  final _addKey = GlobalKey(debugLabel: 'add');
  final _firstNoteKey = GlobalKey(debugLabel: 'first note');
  final _firstNoteHandleKey = GlobalKey(debugLabel: 'first note handle');
  final _scrolledNoteKey = GlobalKey(debugLabel: 'scrolled note');

  String? _lastResult;

  @override
  void initState() {
    super.initState();
    // Show the tutorial once the page is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
  }

  Future<void> _showTutorial() async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final result = await Tutorial(
      // The package does not read the Material theme, so pass it in.
      style: TutorialStyle(
        overlayColor: scheme.scrim.withValues(alpha: 0.6),
        bubbleColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.onSurface,
        descriptionTextStyle: textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
        pageCounterTextStyle: textTheme.bodyLarge!,
      ),
      items: [
        TutorialItem(
          targetKey: _searchKey,
          description: 'Search through all of your notes from here.',
        ),
        TutorialItem(
          targetKey: _firstNoteKey,
          description: 'Drag a note by its handle to reorder the list.',
          animation: const _TapHint(),
          animationAnchorKey: _firstNoteHandleKey,
        ),
        TutorialItem(
          targetKey: _scrolledNoteKey,
          description: 'Steps can scroll their target into view first.',
          beforeStep: () => Scrollable.ensureVisible(
            _scrolledNoteKey.currentContext!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        ),
        TutorialItem(
          targetKey: _addKey,
          description: 'Tap here to write a new note.',
        ),
      ],
    ).show(context);

    if (!mounted) return;
    setState(() => _lastResult = result.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _lastResult == null ? 'Notes' : 'Notes (tutorial: $_lastResult)',
        ),
        actions: [
          IconButton(
            key: _searchKey,
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Show tutorial again',
            icon: const Icon(Icons.help_outline),
            onPressed: _showTutorial,
          ),
        ],
      ),
      // A Column inside a scroll view rather than a lazy ListView, so every
      // target exists before the tutorial scrolls to it.
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < _noteCount; i++)
              ListTile(
                key: switch (i) {
                  0 => _firstNoteKey,
                  _scrolledNote => _scrolledNoteKey,
                  _ => null,
                },
                title: Text('Note ${i + 1}'),
                subtitle: const Text('Lorem ipsum dolor sit amet'),
                trailing: Icon(
                  Icons.drag_handle,
                  key: i == 0 ? _firstNoteHandleKey : null,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: _addKey,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A pulsing circle, standing in for a Lottie of a finger.
class _TapHint extends StatefulWidget {
  const _TapHint();

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.4,
        end: 0.7,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.5),
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}
