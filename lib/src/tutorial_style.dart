import 'package:flutter/widgets.dart';

import 'tutorial_bubble.dart';

/// Visual configuration of a [Tutorial].
///
/// The package depends on the widgets layer only, so it works the same under
/// Material, Cupertino or a custom design system. Nothing is read from an
/// ambient theme: pass your theme's colours and text styles here.
@immutable
class TutorialStyle {
  /// Creates a tutorial style.
  const TutorialStyle({
    this.overlayColor = const Color(0x99000000),
    this.bubbleColor = const Color(0xFFFFFFFF),
    this.foregroundColor = const Color(0xDE000000),
    this.descriptionTextStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    this.pageCounterTextStyle = const TextStyle(fontSize: 16),
    this.currentPageTextStyle = const TextStyle(fontWeight: FontWeight.w700),
    this.bubbleBorderRadius = const BorderRadius.all(Radius.circular(10)),
    this.highlightPadding = 6,
    this.highlightRadius = const Radius.circular(8),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOutCubicEmphasized,
    this.closeIcon,
    this.previousIcon,
    this.nextIcon,
    this.doneIcon,
    this.closeLabel = 'Close',
    this.previousLabel = 'Previous',
    this.nextLabel = 'Next',
    this.doneLabel = 'Done',
    this.bubbleBuilder,
    this.bubbleMaxWidth,
    this.pointerBuilder,
    this.pointerSize = const Size(32, 28),
    this.pointerOverlap = 1,
  });

  /// Colour of the dimmed background around the highlighted widget.
  final Color overlayColor;

  /// Colour of the description bubble and its pointer.
  final Color bubbleColor;

  /// Colour of the text and of the default icons inside the bubble.
  final Color foregroundColor;

  /// Style of the description text, merged over a base style in
  /// [foregroundColor].
  final TextStyle descriptionTextStyle;

  /// Style of the "1 / 3" page counter, merged over a base style in
  /// [foregroundColor].
  final TextStyle pageCounterTextStyle;

  /// Style of the current page number, merged over [pageCounterTextStyle].
  final TextStyle currentPageTextStyle;

  /// Corner radius of the description bubble.
  final BorderRadius bubbleBorderRadius;

  /// Space between the highlighted widget and the edge of the cut-out.
  final double highlightPadding;

  /// Corner radius of the cut-out around the highlighted widget.
  final Radius highlightRadius;

  /// Duration of the transition between steps.
  final Duration animationDuration;

  /// Curve of the transition between steps.
  final Curve animationCurve;

  /// Icon of the button that closes the tutorial. Defaults to a cross.
  final Widget? closeIcon;

  /// Icon of the button that goes back a step. Defaults to a left chevron.
  final Widget? previousIcon;

  /// Icon of the button that goes forward a step. Defaults to a right
  /// chevron.
  final Widget? nextIcon;

  /// Icon of the button that finishes the tutorial on the last step. Defaults
  /// to a check mark.
  final Widget? doneIcon;

  /// Accessibility label of the close button.
  final String closeLabel;

  /// Accessibility label of the previous button.
  final String previousLabel;

  /// Accessibility label of the next button.
  final String nextLabel;

  /// Accessibility label of the done button on the last step.
  final String doneLabel;

  /// Builds the bubble in place of the default one, to match an app's own
  /// look: a textured card, its own buttons, or none at all for a step the
  /// app moves on from by itself (see [Tutorial.start]).
  ///
  /// The bubble is given the width the layout allows (see [bubbleMaxWidth])
  /// and sizes its own height. When set, [bubbleColor],
  /// [bubbleBorderRadius], [foregroundColor], the text styles and the icons
  /// and labels of the buttons are not used.
  final TutorialBubbleBuilder? bubbleBuilder;

  /// Widest the bubble may be. Narrower than the overlay, it is centred on
  /// the pointer and kept on screen. Defaults to the overlay's width less a
  /// margin on each side.
  final double? bubbleMaxWidth;

  /// Builds the pointer in place of the default triangle, laid out in
  /// [pointerSize]. It is drawn under the bubble.
  final TutorialPointerBuilder? pointerBuilder;

  /// Size of the pointer between the bubble and the target.
  final Size pointerSize;

  /// How far the bubble overlaps the pointer, so a pointer can be tucked
  /// under the bubble's edge. The default overlaps by a pixel so no hairline
  /// shows between them.
  final double pointerOverlap;

  /// Creates a copy of this style with the given fields replaced.
  TutorialStyle copyWith({
    Color? overlayColor,
    Color? bubbleColor,
    Color? foregroundColor,
    TextStyle? descriptionTextStyle,
    TextStyle? pageCounterTextStyle,
    TextStyle? currentPageTextStyle,
    BorderRadius? bubbleBorderRadius,
    double? highlightPadding,
    Radius? highlightRadius,
    Duration? animationDuration,
    Curve? animationCurve,
    Widget? closeIcon,
    Widget? previousIcon,
    Widget? nextIcon,
    Widget? doneIcon,
    String? closeLabel,
    String? previousLabel,
    String? nextLabel,
    String? doneLabel,
    TutorialBubbleBuilder? bubbleBuilder,
    double? bubbleMaxWidth,
    TutorialPointerBuilder? pointerBuilder,
    Size? pointerSize,
    double? pointerOverlap,
  }) {
    return TutorialStyle(
      overlayColor: overlayColor ?? this.overlayColor,
      bubbleColor: bubbleColor ?? this.bubbleColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      pageCounterTextStyle: pageCounterTextStyle ?? this.pageCounterTextStyle,
      currentPageTextStyle: currentPageTextStyle ?? this.currentPageTextStyle,
      bubbleBorderRadius: bubbleBorderRadius ?? this.bubbleBorderRadius,
      highlightPadding: highlightPadding ?? this.highlightPadding,
      highlightRadius: highlightRadius ?? this.highlightRadius,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      closeIcon: closeIcon ?? this.closeIcon,
      previousIcon: previousIcon ?? this.previousIcon,
      nextIcon: nextIcon ?? this.nextIcon,
      doneIcon: doneIcon ?? this.doneIcon,
      closeLabel: closeLabel ?? this.closeLabel,
      previousLabel: previousLabel ?? this.previousLabel,
      nextLabel: nextLabel ?? this.nextLabel,
      doneLabel: doneLabel ?? this.doneLabel,
      bubbleBuilder: bubbleBuilder ?? this.bubbleBuilder,
      bubbleMaxWidth: bubbleMaxWidth ?? this.bubbleMaxWidth,
      pointerBuilder: pointerBuilder ?? this.pointerBuilder,
      pointerSize: pointerSize ?? this.pointerSize,
      pointerOverlap: pointerOverlap ?? this.pointerOverlap,
    );
  }
}
