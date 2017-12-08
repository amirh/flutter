// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is the test for the private implementation of animated icons.
// To make the private API accessible from the test we do not import the 
// material material_animated_icons library, but instead, this test file is an
// implementation of that library, using some of the parts of the real
// material_animated_icons, this give the test access to the private APIs.
library material_animated_icons;

import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui show Paint, Path, Canvas;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

part '../../lib/src/material_animated_icons/animated_icons.dart';
part '../../lib/src/material_animated_icons/animated_icons_data.dart';
part '../../lib/src/material_animated_icons/data/menu_arrow.g.dart';

class MockCanvas extends Mock implements ui.Canvas {}
class MockPath extends Mock implements ui.Path {}

void main () {
  group('Interpolate points', () {
    test('- single point', () {
      final List<Offset> points = const <Offset>[
        const Offset(25.0, 1.0),
      ];
      expect(_interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 0.5, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 1.0, Offset.lerp), const Offset(25.0, 1.0));
    });

    test('- two points', () {
      final List<Offset> points = const <Offset>[
        const Offset(25.0, 1.0),
        const Offset(12.0, 12.0),
      ];
      expect(_interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 0.5, Offset.lerp), const Offset(18.5, 6.5));
      expect(_interpolate(points, 1.0, Offset.lerp), const Offset(12.0, 12.0));
    });

    test('- three points', () {
      final List<Offset> points = const <Offset>[
        const Offset(25.0, 1.0),
        const Offset(12.0, 12.0),
        const Offset(23.0, 9.0),
      ];
      expect(_interpolate(points, 0.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 0.25, Offset.lerp), const Offset(18.5, 6.5));
      expect(_interpolate(points, 0.5, Offset.lerp), const Offset(12.0, 12.0));
      expect(_interpolate(points, 0.75, Offset.lerp), const Offset(17.5, 10.5));
      expect(_interpolate(points, 1.0, Offset.lerp), const Offset(23.0, 9.0));
    });

    test('- clamp progress to [0,1]', () {
      final List<Offset> points = const <Offset>[
        const Offset(25.0, 1.0),
        const Offset(12.0, 12.0),
      ];
      expect(_interpolate(points, -1.0, Offset.lerp), const Offset(25.0, 1.0));
      expect(_interpolate(points, 1.5, Offset.lerp), const Offset(12.0, 12.0));
    });
  });

  group('_AnimatedIconPainter', () {
    final Size size = const Size(48.0, 48.0);
    final MockCanvas mockCanvas = new MockCanvas();
    List<MockPath> generatedPaths;
    final _UiPathFactory pathFactory = () {
      final MockPath path = new MockPath();
      generatedPaths.add(path);
      return path;
    };

    setUp(() {
      generatedPaths = <MockPath> [];
    });

    test('progress 0', () {
      final _AnimatedIconPainter painter = new _AnimatedIconPainter(
        movingBar.paths,
        const AlwaysStoppedAnimation<double>(0.0),
        const Color(0xFF00FF00),
        pathFactory
      );
      painter.paint(mockCanvas,  size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<dynamic>[
        generatedPaths[0].moveTo(0.0, 0.0),
        generatedPaths[0].lineTo(48.0, 0.0),
        generatedPaths[0].lineTo(48.0, 10.0),
        generatedPaths[0].lineTo(0.0, 10.0),
        generatedPaths[0].lineTo(0.0, 0.0),
        generatedPaths[0].close(),
      ]);
    });

    test('progress 1', () {
      final _AnimatedIconPainter painter = new _AnimatedIconPainter(
        movingBar.paths,
        const AlwaysStoppedAnimation<double>(1.0),
        const Color(0xFF00FF00),
        pathFactory
      );
      painter.paint(mockCanvas,  size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<dynamic>[
        generatedPaths[0].moveTo(0.0, 38.0),
        generatedPaths[0].lineTo(48.0, 38.0),
        generatedPaths[0].lineTo(48.0, 48.0),
        generatedPaths[0].lineTo(0.0, 48.0),
        generatedPaths[0].lineTo(0.0, 38.0),
        generatedPaths[0].close(),
      ]);
    });

    test('clamped progress', () {
      final _AnimatedIconPainter painter = new _AnimatedIconPainter(
        movingBar.paths,
        const AlwaysStoppedAnimation<double>(1.5),
        const Color(0xFF00FF00),
        pathFactory
      );
      painter.paint(mockCanvas,  size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<dynamic>[
        generatedPaths[0].moveTo(0.0, 38.0),
        generatedPaths[0].lineTo(48.0, 38.0),
        generatedPaths[0].lineTo(48.0, 48.0),
        generatedPaths[0].lineTo(0.0, 48.0),
        generatedPaths[0].lineTo(0.0, 38.0),
        generatedPaths[0].close(),
      ]);
    });

    test('interpolated frame', () {
      final _AnimatedIconPainter painter = new _AnimatedIconPainter(
        movingBar.paths,
        const AlwaysStoppedAnimation<double>(0.5),
        const Color(0xFF00FF00),
        pathFactory
      );
      painter.paint(mockCanvas,  size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<dynamic>[
        generatedPaths[0].moveTo(0.0, 19.0),
        generatedPaths[0].lineTo(48.0, 19.0),
        generatedPaths[0].lineTo(48.0, 29.0),
        generatedPaths[0].lineTo(0.0, 29.0),
        generatedPaths[0].lineTo(0.0, 19.0),
        generatedPaths[0].close(),
      ]);
    });

    test('curved frame', () {
      final _AnimatedIconPainter painter = new _AnimatedIconPainter(
        bow.paths,
        const AlwaysStoppedAnimation<double>(1.0),
        const Color(0xFF00FF00),
        pathFactory
      );
      painter.paint(mockCanvas,  size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<dynamic>[
        generatedPaths[0].moveTo(0.0, 24.0),
        generatedPaths[0].cubicTo(16.0, 48.0, 32.0, 48.0, 48.0, 24.0),
        generatedPaths[0].lineTo(0.0, 24.0),
        generatedPaths[0].close(),
      ]);
    });

    test('interpolated curved frame', () {
      final _AnimatedIconPainter painter = new _AnimatedIconPainter(
        bow.paths,
        const AlwaysStoppedAnimation<double>(0.25),
        const Color(0xFF00FF00),
        pathFactory
      );
      painter.paint(mockCanvas,  size);
      expect(generatedPaths.length, 1);

      verifyInOrder(<dynamic>[
        generatedPaths[0].moveTo(0.0, 24.0),
        generatedPaths[0].cubicTo(16.0, 17.0, 32.0, 17.0, 48.0, 24.0),
        generatedPaths[0].lineTo(0.0, 24.0),
        generatedPaths[0].close(),
      ]);
    });
  });
}

const _AnimatedIconData movingBar = const _AnimatedIconData(
  const Size(48.0, 48.0),
  const <_PathFrames> [
    const _PathFrames(
      opacities: const <double> [1.0, 0.2],
      commands: const <_PathCommand> [
        const _PathMoveTo(
          const <Offset> [
            const Offset(0.0, 0.0),
            const Offset(0.0, 38.0),
          ],
        ),
        const _PathLineTo(
          const <Offset> [
            const Offset(48.0, 0.0),
            const Offset(48.0, 38.0),
          ],
        ),
        const _PathLineTo(
          const <Offset> [
            const Offset(48.0, 10.0),
            const Offset(48.0, 48.0),
          ],
        ),
        const _PathLineTo(
          const <Offset> [
            const Offset(0.0, 10.0),
            const Offset(0.0, 48.0),
          ],
        ),
        const _PathLineTo(
          const <Offset> [
            const Offset(0.0, 0.0),
            const Offset(0.0, 38.0),
          ],
        ),
        const _PathClose(),
      ],
    ),
  ],
);

const _AnimatedIconData bow = const _AnimatedIconData(
  const Size(48.0, 48.0),
  const <_PathFrames> [
    const _PathFrames(
      opacities: const <double> [1.0, 1.0],
      commands: const <_PathCommand> [
        const _PathMoveTo(
          const <Offset> [
            const Offset(0.0, 24.0),
            const Offset(0.0, 24.0),
            const Offset(0.0, 24.0),
          ],
        ),
        const _PathCubicTo(
          const <Offset> [
            const Offset(16.0, 24.0),
            const Offset(16.0, 10.0),
            const Offset(16.0, 48.0),
          ],
          const <Offset> [
            const Offset(32.0, 24.0),
            const Offset(32.0, 10.0),
            const Offset(32.0, 48.0),
          ],
          const <Offset> [
            const Offset(48.0, 24.0),
            const Offset(48.0, 24.0),
            const Offset(48.0, 24.0),
          ],
        ),
        const _PathLineTo(
          const <Offset> [
            const Offset(0.0, 24.0),
            const Offset(0.0, 24.0),
            const Offset(0.0, 24.0),
          ],
        ),
        const _PathClose(),
      ],
    ),
  ],
);
