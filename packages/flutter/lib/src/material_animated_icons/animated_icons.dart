// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of material_animated_icons;

// The code for drawing animated icons is kept in a private API, as we are not
// yet ready for exposing a public API for (partial) vector graphics support.
// See: https://github.com/flutter/flutter/issues/1831 for details regarding
// generic vector graphics support in Flutter.

/// Shows an animated icon at a given animation [progress].
///
/// The available icons are specified in [AnimatedIcons].
class AnimatedIcon extends StatelessWidget {

  const AnimatedIcon({
    @required this.progress,
    @required this.color,
    @required this.icon,
    this.semanticLabel,
    this.textDirection,
    // TODO(amirh): add a parameter for controlling scaling behavior.
  }) : assert (progress != null),
       assert (color != null),
       assert (icon != null);

  /// The animation progress for the animated icon.
  /// The value must be between 0 and 1.
  ///
  /// This determines the actual frame that is displayed.
  final Animation<double> progress;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the current [IconTheme] color, if any.
  ///
  /// The given color will be adjusted by the opacity of the current
  /// [IconTheme], if any.
  ///
  /// If no [IconTheme]s are specified, icons will default to black.
  ///
  /// In material apps, if there is a [Theme] without any [IconTheme]s
  /// specified, icon colors default to white if the theme is dark
  /// and black if the theme is light.
  /// See [Theme] to set the current theme and [ThemeData.brightness]
  /// for setting the current theme's brightness.
  final Color color;

  /// The icon to display. Available icons are listed in [AnimatedIcons].
  final AnimatedIconData icon;

  /// Semantic label for the icon.
  ///
  /// This would be read out in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  /// See also:
  ///
  ///  * [Semantics.label], which is set to [semanticLabel] in the underlying
  ///    [Semantics] widget.
  final String semanticLabel;

  /// The text direction to use for rendering the icon.
  ///
  /// If this is null, the ambient [Directionality] is used instead.
  ///
  /// Some icons follow the reading direction. For example, "back" buttons point
  /// left in left-to-right environments and right in right-to-left
  /// environments. Such icons have their [IconData.matchTextDirection] field
  /// set to true, and the [Icon] widget uses the [textDirection] to determine
  /// the orientation in which to draw the icon.
  ///
  /// This property has no effect if the [icon]'s [IconData.matchTextDirection]
  /// field is false, but for consistency a text direction value must always be
  /// specified, either directly using this property or using [Directionality].
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {

    // TODO(amirh): implement semantics and text direction.
    return new _AnimatedIcon(
      progress: progress,
      color: color,
      icon: icon,
    );
  }
}
