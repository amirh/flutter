// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'fake_platform_views.dart';

void main() {
  FakePlatformViewsController viewsController;

  group('Android', () {
    setUp(() {
      viewsController = new FakePlatformViewsController(TargetPlatform.android);
    });

    test('create Android view of unregistered type', () async {
      expect(
          () => PlatformViewsService.initAndroidView(
              id: 0, viewType: 'web').setSize(const Size(100.0, 100.0)),
          throwsA(const isInstanceOf<PlatformException>()));
    });

    test('create Android views', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      await PlatformViewsService.initAndroidView(
          id: 1, viewType: 'webview').setSize(const Size(200.0, 300.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakePlatformView>[
            new FakePlatformView(0, 'webview', const Size(100.0, 100.0)),
            new FakePlatformView(1, 'webview', const Size(200.0, 300.0)),
          ]));
    });

    test('reuse Android view id', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      expect(
          () => PlatformViewsService.initAndroidView(
              id: 0, viewType: 'web').setSize(const Size(100.0, 100.0)),
          throwsA(const isInstanceOf<PlatformException>()));
    });

    test('dispose Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview');
      await viewController.setSize(const Size(200.0, 300.0));

      viewController.dispose();
      expect(
          viewsController.views,
          unorderedEquals(<FakePlatformView>[
            new FakePlatformView(0, 'webview', const Size(100.0, 100.0)),
          ]));
    });

    test('dispose inexisting Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview');
      await viewController.setSize(const Size(200.0, 300.0));
      await viewController.dispose();
      await viewController.dispose();
    });

    test('resize Android view', () async {
      viewsController.registerViewType('webview');
      await PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview').setSize(const Size(100.0, 100.0));
      final AndroidViewController viewController =
          PlatformViewsService.initAndroidView(id: 1, viewType: 'webview');
      await viewController.setSize(const Size(200.0, 300.0));
      await viewController.setSize(const Size(500.0, 500.0));
      expect(
          viewsController.views,
          unorderedEquals(<FakePlatformView>[
            new FakePlatformView(0, 'webview', const Size(100.0, 100.0)),
            new FakePlatformView(1, 'webview', const Size(500.0, 500.0)),
          ]));
    });

    test('OnPlatformViewCreated callback', () async {
      viewsController.registerViewType('webview');
      final List<int> createdViews = <int>[];
      final OnPlatformViewCreated callback = (int id) { createdViews.add(id); };

      final AndroidViewController controller1 = PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview', onPlatformViewCreated:  callback);
      expect(createdViews, isEmpty);

      await controller1.setSize(const Size(100.0, 100.0));
      expect(createdViews, orderedEquals(<int>[0]));

      final AndroidViewController controller2 = PlatformViewsService.initAndroidView(
          id: 5, viewType: 'webview', onPlatformViewCreated:  callback);
      expect(createdViews, orderedEquals(<int>[0]));

      await controller2.setSize(const Size(100.0, 200.0));
      expect(createdViews, orderedEquals(<int>[0, 5]));

    });

    test('send touches to Android views', () async {
      viewsController.registerViewType('webview');
      final AndroidViewController view1 = PlatformViewsService.initAndroidView(
          id: 0, viewType: 'webview');
      final AndroidViewController view2 = PlatformViewsService.initAndroidView(
          id: 1, viewType: 'webview');

      await view1.setSize(const Size(100.0, 100.0));
      await view2.setSize(const Size(200.0, 300.0));

      view1.sendPointerEvent(
          downTime: 1,
          eventTime: 2,
          action: 3,
          x: 4.0,
          y: 5.0,
          pressure: 6.0,
          size: 7.0,
          metaState: 8,
          xPrecision: 9.0,
          yPrecision: 10.0,
          deviceId: 11,
          edgeFlags: 12
      );
      view2.sendPointerEvent(
          downTime: 3,
          eventTime: 4,
          action: 5,
          x: 6.0,
          y: 7.0,
          pressure: 8.0,
          size: 9.0,
          metaState: 10,
          xPrecision: 11.0,
          yPrecision: 12.0,
          deviceId: 13,
          edgeFlags: 14
      );
      expect(
          viewsController.getMotionEventsForView(0),
          orderedEquals(<FakeMotionEvent>[
            const FakeMotionEvent(1, 2, 3, 4.0, 5.0, 6.0, 7.0, 8, 9.0, 10.0, 11, 12)
          ])
      );
      expect(
          viewsController.getMotionEventsForView(1),
          orderedEquals(<FakeMotionEvent>[
            const FakeMotionEvent(3, 4, 5, 6.0, 7.0, 8.0, 9.0, 10, 11.0, 12.0, 13, 14)
          ])
      );
    });

    test('pointerAction',() {
     expect(
         AndroidViewController.pointerAction(1, AndroidViewController.kActionPointerDown),
         1
     );
    });
  });
}
