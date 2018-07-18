// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'layer.dart';
import 'object.dart';


enum _PlatformViewState {
  uninitialized,
  resizing,
  ready,
}

/// A render object for an Android view.
///
/// [RenderAndroidView] is responsible for sizing and displaying an Android [View](https://developer.android.com/reference/android/view/View).
///
/// The render object's layout behavior is to fill all available space, the parent of this object must
/// provide bounded layout constraints
///
/// See also:
///  * [AndroidView] which is a widget that is used to show an Android view.
///  * [PlatformViewsService] which is a service for controlling platform views.
class RenderAndroidView extends RenderBox {

  /// Creates a render object for an Android view.
  RenderAndroidView({
    @required AndroidViewController viewController,
  }) : assert(viewController != null),
       _viewController = viewController {
        _gestureRecognizer = new _PlatformViewGestureRecognizer(viewController, this);
  }

  _PlatformViewState _state = _PlatformViewState.uninitialized;

  /// The Android view controller for the Android view associated with this render object.
  AndroidViewController get viewcontroller => _viewController;
  AndroidViewController _viewController;
  /// Sets a new Android view controller.
  ///
  /// `viewController` must not be null.
  set viewController(AndroidViewController viewController) {
    assert(_viewController != null);
    if (_viewController == viewController)
      return;
    _viewController = viewController;
    _sizePlatformView();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _PlatformViewGestureRecognizer _gestureRecognizer;

  @override
  void performResize() {
    size = constraints.biggest;
    _sizePlatformView();
  }

  Future<Null> _sizePlatformView() async {
    if (_state == _PlatformViewState.resizing) {
      return;
    }

    _state = _PlatformViewState.resizing;

    Size targetSize;
    do {
      targetSize = size;
      await _viewController.setSize(size);
      // We've resized the platform view to targetSize, but it is possible that
      // while we were resizing the render object's size was changed again.
      // In that case we will resize the platform view again.
    } while (size != targetSize);

    _state = _PlatformViewState.ready;
    markNeedsPaint();
  }


  @override
  void paint(PaintingContext context, Offset offset) {
    if (_viewController.textureId == null)
      return;

    context.addLayer(new TextureLayer(
      rect: offset & size,
      textureId: _viewController.textureId,
    ));
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    bool hitTarget = false;
    if (size.contains(position)) {
      hitTarget = hitTestChildren(result, position: position) || hitTestSelf(position);
      if(hitTarget)
        result.add(new BoxHitTestEntry(this, position));
    }
    return hitTarget;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  int _numPointers = 0;
  int _downTime;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _gestureRecognizer.addPointer(event);
    }
    // int action;
    // switch(event.runtimeType){
    //   case PointerDownEvent:
    //     if (_numPointers == 0)
    //       _downTime = event.timeStamp.inMilliseconds;
    //     action = _numPointers == 0 ? AndroidViewController.kActionDown
    //         : AndroidViewController.pointerAction(_numPointers, AndroidViewController.kActionDown);
    //     _numPointers++;
    //     break;
    //   case PointerUpEvent:
    //     _numPointers--;
    //     action = _numPointers == 0 ? AndroidViewController.kActionUp
    //         : AndroidViewController.pointerAction(_numPointers, AndroidViewController.kActionUp);
    //     break;
    //   case PointerMoveEvent:
    //     action = AndroidViewController.kActionMove;
    //     break;
    //   case PointerCancelEvent:
    //     action = AndroidViewController.kActionCancel;
    //     break;
    //   default:
    //     return;
    // }

    // final Offset globalPosition = globalToLocal(event.position);
    // _viewController.sendPointerEvent(
    //     downTime: _downTime,
    //     eventTime: event.timeStamp.inMilliseconds,
    //     action: action,
    //     x: globalPosition.dx,
    //     y: globalPosition.dy,
    //     pressure: event.pressure,
    //     size: 1.0,
    //     metaState: 0,
    //     xPrecision: 1.0,
    //     yPrecision: 1.0,
    //     deviceId: event.device,
    //     edgeFlags: 0
    // );
  }

}

class _PlatformViewGestureRecognizer extends OneSequenceGestureRecognizer {


  final Map<int, AndroidPointerCoords> pointerPositions = <int, AndroidPointerCoords>{};
  final Map<int, AndroidPointerProperties> pointerProperties = <int, AndroidPointerProperties>{};
  int nextPointerId = 0;
  final Set<int> acceptedPointers = new HashSet<int>();
  final Set<int> potentialPointers = new HashSet<int>();
  final List<PointerEvent> cachedPointerEvents = <PointerEvent>[];

  final OneSequenceGestureRecognizer tap = new ScaleGestureRecognizer();

  final AndroidViewController viewController;
  final RenderBox renderBox;

  Duration downTime;

  _PlatformViewGestureRecognizer(this.viewController, this.renderBox) {
    //tap.onTap = () { print('tap'); };
    team = new GestureArenaTeam();
    team.captain  = this;
    tap.team = team;
  }

  @override
  void addPointer(PointerDownEvent event) {
    tap.addPointer(event);
    startTrackingPointer(event.pointer);
    potentialPointers.add(event.pointer);
    pointerProperties[event.pointer] = new AndroidPointerProperties(id: nextPointerId++, toolType: 1);
    downTime ??= event.timeStamp;
  }

  @override
  String get debugDescription => 'platform view';

  @override
  void didStopTrackingLastPointer(int pointer) {
    scheduleMicrotask(() {
      downTime = null;
      nextPointerId = 0;
    });
  }

  @override
  void handleEvent(PointerEvent event) {
    int pointer = event.pointer;
    if (!potentialPointers.contains(pointer) && !acceptedPointers.contains(pointer))
      return;
    if(potentialPointers.contains(event.pointer)) {
      cachedPointerEvents.add(event);
    } else {
      pointerPositions[event.pointer] = coordsFor(event);
      sendPointerEvent(event);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void stopTrackingPointer(int pointer) {
    super.stopTrackingPointer(pointer);
    scheduleMicrotask(() {
      pointerPositions.remove(pointer);
    });
  }

  @override
  void acceptGesture(int pointer) {
    acceptedPointers.addAll(potentialPointers);
    if (potentialPointers.isNotEmpty) {
      flushPointerCache();
      potentialPointers.clear();
    }

    // Win the arenas for all pointers.
    // TODO(amir) do we actually need this?
    resolve(GestureDisposition.accepted);

    print('accepted $pointer');
  }

  @override
  void rejectGesture(int pointer) {
    print('rejected $pointer');
    cachedPointerEvents.removeWhere((e) => e.pointer == pointer);
    potentialPointers.remove(pointer);
  }

  void flushPointerCache() {
    while(cachedPointerEvents.isNotEmpty) {
      PointerEvent e = cachedPointerEvents.removeAt(0);
      pointerPositions[e.pointer] = coordsFor(e);
      sendPointerEvent(e);
    }
  }

  AndroidPointerCoords coordsFor(PointerEvent event) {
    final Offset position = renderBox.globalToLocal(event.position);
    return new AndroidPointerCoords(
        orientation: event.orientation,
        pressure: event.pressure,
        size: 0.333,
        toolMajor: event.radiusMajor,
        toolMinor: event.radiusMinor,
        touchMajor: event.radiusMajor,
        touchMinor: event.radiusMinor,
        x: position.dx,
        y: position.dy
    );
  }

  void sendPointerEvent(PointerEvent event) {
    final List<int> pointers = pointerPositions.keys.toList();
    int pointerIdx = pointers.indexOf(event.pointer);
    int numPointers = pointers.length;

    // Android MotionEvent objects can batch information on multiple pointers.
    // Flutter breaks these such batched events into multiple PointerEvent objects.
    // When there are multiple active pointers we accumulate the information for all pointers
    // as we get PointerEvents, and only send it to the embedded Android view when
    // we see the last pointer. This way we achieve the same batching as Android.
    if(isAllPointersEvent(event) && pointerIdx < numPointers - 1)
      return;

    int action;
    switch(event.runtimeType){
      case PointerDownEvent:
        action = numPointers == 1 ? AndroidViewController.kActionDown
            : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerDown);
        break;
      case PointerUpEvent:
        action = numPointers == 1 ? AndroidViewController.kActionUp
            : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerUp);
        break;
      case PointerMoveEvent:
        action = AndroidViewController.kActionMove;
        break;
      case PointerCancelEvent:
        action = AndroidViewController.kActionCancel;
        break;
      default:
        return;
    }

    final AndroidMotionEvent androidMotionEvent = new AndroidMotionEvent(
        downTime: downTime.inMilliseconds,
        eventTime: event.timeStamp.inMilliseconds,
        action: action,
        pointerCount: pointerPositions.length,
        pointerProperties: pointers.map((int i) => pointerProperties[i]).toList(),
        pointerCoords: pointers.map((int i) => pointerPositions[i]).toList(),
        metaState: 0,
        buttonState: 0,
        xPrecision: 1.0,
        yPrecision: 1.0,
        deviceId: 0,
        edgeFlags: 0,
        source: 0,
        flags: 0
    );
    viewController.sendPointerEvent(androidMotionEvent);
  }

  bool isAllPointersEvent(PointerEvent event) =>
      !(event is PointerDownEvent) && !(event is PointerUpEvent);

}
