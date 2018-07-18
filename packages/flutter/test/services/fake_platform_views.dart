// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class FakePlatformViewsController {
  FakePlatformViewsController(this.targetPlatform) : assert(targetPlatform != null) {
    SystemChannels.platform_views.setMockMethodCallHandler(_onMethodCall);
  }

  final TargetPlatform targetPlatform;
  final Map<int, FakePlatformView> _views = <int, FakePlatformView>{};
  final Map<int, List<FakeMotionEvent>> _motionEvents = <int, List<FakeMotionEvent>>{};
  final Set<String> _registeredViewTypes = new Set<String>();

  int _textureCounter = 0;

  void registerViewType(String viewType) {
    _registeredViewTypes.add(viewType);
  }

  Future<dynamic> _onMethodCall(MethodCall call) {
    if (targetPlatform == TargetPlatform.android)
      return _onMethodCallAndroid(call);
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _onMethodCallAndroid(MethodCall call) {
    switch(call.method) {
      case 'create':
        return _create(call);
      case 'dispose':
        return _dispose(call);
      case 'resize':
        return _resize(call);
      case 'touch':
        return _touch(call);
    }
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _create(MethodCall call) {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final String viewType = args['viewType'];
    final double width = args['width'];
    final double height = args['height'];

    if (_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to create an already created platform view, view id: $id',
      );

    if (!_registeredViewTypes.contains(viewType))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to create a platform view of unregistered type: $viewType',
      );

    _views[id] = new FakePlatformView(id, viewType, new Size(width, height));
    _motionEvents[id] = <FakeMotionEvent> [];
    final int textureId = _textureCounter++;
    return new Future<int>.sync(() => textureId);
  }

  Future<dynamic> _dispose(MethodCall call) {
    final int id = call.arguments;

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to dispose a platform view with unknown id: $id',
      );

    _views.remove(id);
    _motionEvents.remove(id);
    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _resize(MethodCall call) {
    final Map<dynamic, dynamic> args = call.arguments;
    final int id = args['id'];
    final double width = args['width'];
    final double height = args['height'];

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    _views[id].size = new Size(width, height);

    return new Future<Null>.sync(() => null);
  }

  Future<dynamic> _touch(MethodCall call) {
    final List<dynamic> args = call.arguments;
    final int id = args[0];
    final int downTime = args[1];
    final int eventTime = args[2];
    final int action = args[3];
    final double x = args[4];
    final double y = args[5];
    final double pressure = args[6];
    final double size = args[7];
    final int metaState = args[8];
    final double xPrecision = args[9];
    final double yPrecision = args[10];
    final int deviceId = args[11];
    final int edgeFlags = args[12];

    if (!_views.containsKey(id))
      throw new PlatformException(
        code: 'error',
        message: 'Trying to resize a platform view with unknown id: $id',
      );

    _motionEvents[id].add(new FakeMotionEvent(
        downTime,
        eventTime,
        action,
        x,
        y,
        pressure,
        size,
        metaState,
        xPrecision,
        yPrecision,
        deviceId,
        edgeFlags
    ));

    return new Future<Null>.sync(() => null);
  }

  Iterable<FakePlatformView> get views => _views.values;

  Iterable<FakeMotionEvent> getMotionEventsForView(int id) {
    return _motionEvents[id];
  }
}

class FakePlatformView {

  FakePlatformView(this.id, this.type, this.size);

  final int id;
  final String type;
  Size size;

  @override
  bool operator ==(dynamic other) {
    if (other is! FakePlatformView)
      return false;
    final FakePlatformView typedOther = other;
    return id == typedOther.id &&
        type == typedOther.type &&
        size == typedOther.size;
  }

  @override
  int get hashCode => hashValues(id, type, size);

  @override
  String toString() {
    return 'FakePlatformView(id: $id, type: $type, size: $size)';
  }
}

class FakeMotionEvent {
  const FakeMotionEvent(
    this.downTime,
    this.eventTime,
    this.action,
    this.x,
    this.y,
    this.pressure,
    this.size,
    this.metaState,
    this.xPrecision,
    this.yPrecision,
    this.deviceId,
    this.edgeFlags
  );

  final int downTime;
  final int eventTime;
  final int action;
  final double x;
  final double y;
  final double pressure;
  final double size;
  final int metaState;
  final double xPrecision;
  final double yPrecision;
  final int deviceId;
  final int edgeFlags;

  @override
  bool operator ==(dynamic other) {
    if (other is! FakeMotionEvent)
      return false;
    return downTime == other.downTime &&
        eventTime == other.eventTime &&
        action == other.action &&
        x == other.x &&
        y == other.y &&
        pressure == other.pressure &&
        size == other.size &&
        metaState == other.metaState &&
        xPrecision == other.xPrecision &&
        yPrecision == other.yPrecision &&
        deviceId == other.deviceId &&
        edgeFlags == other.edgeFlags;
  }

  @override
  int get hashCode =>
      hashValues(
        downTime,
        eventTime,
        action,
        x,
        y,
        pressure,
        size,
        metaState,
        xPrecision,
        yPrecision,
        deviceId,
        edgeFlags,
      );

  @override
  String toString() {
    return 'FakeMotionEvent(downTime: $downTime, eventTime: $eventTime, action: $action, x: $x, y: $y, pressure: $pressure, size: $size, metaState: $metaState, xPrecision: $xPrecision, yPrecision: $yPrecision, deviceId: $deviceId, edgeFlags: $edgeFlags)';
  }

}