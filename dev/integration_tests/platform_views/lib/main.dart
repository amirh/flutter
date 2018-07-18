import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/equality.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

MethodChannel channel = const MethodChannel('platform_views_integration');

const String kEventsFileName = 'touchEvents';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Platform Views Integration Test',
      home: new Scaffold(
        body: new PlatformViewPage(),
      ),
    );
  }
}

class PlatformViewPage extends StatefulWidget {
  @override
  State createState() => new PlatformViewState();
}

class PlatformViewState extends State<PlatformViewPage> {
  static const kEventsBufferSize = 1000;

  MethodChannel viewChannel;
  List<Map<String, dynamic>> flutterViewEvents = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> embeddedViewEvents = <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new SizedBox(
            height: 300.0,
            child: new AndroidView(
                viewType: 'simple_view',
                onPlatformViewCreated: onPlatformViewCreated)),
        new Expanded(
          child: new ListView.builder(
            itemBuilder: buildEventTile,
            itemCount: flutterViewEvents.length,
          ),
        ),
        new Row(
          children: <Widget>[
            new RaisedButton(
              child: const Text('RECORD'),
              onPressed: listenToFlutterViewEvents,
            ),
            new RaisedButton(
              child: const Text('CLEAR'),
              onPressed: () {
                setState(() {
                  flutterViewEvents.clear();
                  embeddedViewEvents.clear();
                });
              },
            ),
            new RaisedButton(
              child: const Text('SAVE'),
              onPressed: () {
                StandardMessageCodec codec = const StandardMessageCodec();
                saveRecordedEvents(
                    codec.encodeMessage(flutterViewEvents), context);
              },
            ),
            new RaisedButton(
              child: const Text('PLAY FILE'),
              onPressed: loadAsset,
            )
          ],
        )
      ],
    );
  }

  Future<void> loadAsset() async {
    const StandardMessageCodec codec = const StandardMessageCodec();
    try {
      final ByteData data = await rootBundle.load('packages/assets_for_android_views/assets/touchEvents');
      // Directory outDir = await getExternalStorageDirectory();
      // File file = new File('${outDir.path}/$kEventsFileName');
      // final ByteData data = new Uint8List.fromList(await file.readAsBytes()).buffer.asByteData();
      List<dynamic> a = codec.decodeMessage(data);
      List<Map<String, dynamic>> b = a.cast<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> e) => e.cast<String, dynamic>()).toList();
      await channel.invokeMethod('pipeFlutterViewEvents');
      await viewChannel.invokeMethod('pipeTouchEvents');
      for (Map<String, dynamic> event in b.reversed) {
        int action = event['action'];
        final String actionName = getActionName(getActionMasked(action), action);
        await channel.invokeMethod('synthesizeEvent', event);
      }
      channel.invokeMethod('stopFlutterViewEvents');
      viewChannel.invokeMethod('stopTouchEvents');
    } catch(e) {
      print(e);
    }
  }

  @override
  void initState() {
    channel.setMethodCallHandler(onMethodChannelCall);
  }
  Future<void> saveRecordedEvents(ByteData data, BuildContext context) async {
    if (!await channel.invokeMethod('getStoragePermission')) {
      showMessage(
          context, 'External storage permissions are required to save events');
      return;
    }
    try {
      Directory outDir = await getExternalStorageDirectory();
      // This test only runs on Android so we can assume path separator is '/'.
      File file = new File('${outDir.path}/$kEventsFileName');
      await file.writeAsBytes(data.buffer.asUint8List(0, data.lengthInBytes), flush: true);
      showMessage(context, 'Saved original events to ${file.path}');
    } catch (e) {
      showMessage(context, 'Failed saving ${e.toString()}');
    }
  }

  void showMessage(BuildContext context, String message) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  void onPlatformViewCreated(int id) {
    viewChannel = new MethodChannel('simple_view/$id');
    viewChannel.setMethodCallHandler(onViewMethodChannelCall);
  }

  void listenToFlutterViewEvents() {
    channel.invokeMethod('pipeFlutterViewEvents');
    viewChannel.invokeMethod('pipeTouchEvents');
    new Timer(new Duration(seconds: 3), () {
      channel.invokeMethod('stopFlutterViewEvents');
      viewChannel.invokeMethod('stopTouchEvents');
    });
  }

  Future<dynamic> onMethodChannelCall(MethodCall call) {
    switch (call.method) {
      case 'onTouch':
        final Map<dynamic, dynamic> map = call.arguments;
        flutterViewEvents.insert(0, map.cast<String, dynamic>());
        if (flutterViewEvents.length > kEventsBufferSize)
          flutterViewEvents.removeLast();
        setState(() {});
        break;
    }
  }

  Future<dynamic> onViewMethodChannelCall(MethodCall call) {
    switch (call.method) {
      case 'onTouch':
        final Map<dynamic, dynamic> map = call.arguments;
        embeddedViewEvents.insert(0, map.cast<String, dynamic>());
        if (embeddedViewEvents.length > kEventsBufferSize)
          embeddedViewEvents.removeLast();
        setState(() {});
        break;
    }
  }

  Widget buildEventTile(BuildContext context, int index) {
    if (embeddedViewEvents.length > index)
      return new TouchEventDiff(
          flutterViewEvents[index], embeddedViewEvents[index]);
    return new Text(
        'Unmatched event, action: ${flutterViewEvents[index]['action']}');
  }
}

class TouchEventDiff extends StatelessWidget {
  const TouchEventDiff(this.originalEvent, this.synthesizedEvent);

  final Map<String, dynamic> originalEvent;
  final Map<String, dynamic> synthesizedEvent;

  // Android MotionEvent actions for which a pointer index is encoded in the
  // unmasked action code.
  static const List<int> kPointerActions = <int>[
    0, // DOWN
    1, // UP
    5, // POINTER_DOWN
    6 // POINTER_UP
  ];

  static const double kDoubleErrorMargin = 0.0001;

  @override
  Widget build(BuildContext context) {
    final StringBuffer diff = new StringBuffer();

    diffMaps(originalEvent, synthesizedEvent, diff, excludeKeys: const <String>[
      'pointerProperties', // Compared separately.
      'pointerCoords', // Compared separately.
      'source', // Unused by Flutter.
      'deviceId', // Android documentation says that's an arbitrary number that shouldn't be depended on.
      'action', // Compared separately.
    ]);

    diffActions(diff);
    diffPointerProperties(diff);
    diffPointerCoordsList(diff);

    Color color;
    String msg;
    final int action = synthesizedEvent['action'];
    final String actionName = getActionName(getActionMasked(action), action);
    if (diff.isEmpty) {
      color = Colors.green;
      msg = 'Matched event (action $actionName)';
    } else {
      color = Colors.red;
      msg = '[$actionName] ${diff.toString()}';
    }
    return new GestureDetector(
      onLongPress: () {
        print('expected:');
        prettyPrintEvent(originalEvent);
        print('\nactual:');
        prettyPrintEvent(synthesizedEvent);
      },
      child: new Container(
        color: color,
        margin: const EdgeInsets.only(bottom: 2.0),
        child: new Text(msg),
      ),
    );
  }

  void prettyPrintEvent(Map<String, dynamic> event) {
    final StringBuffer buffer = new StringBuffer();
    final int action = event['action'];
    final int maskedAction = getActionMasked(action);
    final String actionName = getActionName(maskedAction, action);

    buffer.write('$actionName ');
    if (maskedAction == 5 || maskedAction == 6) {
     buffer.write('pointer: ${getPointerIdx(action)} ');
    }

    final List<Map<dynamic, dynamic>> coords = event['pointerCoords'].cast<Map<dynamic, dynamic>>();
    for (int i = 0; i < coords.length; i++) {
      buffer.write('p$i x: ${coords[i]['x']} y: ${coords[i]['y']}, pressure: ${coords[i]['pressure']} ');
    }
    print(buffer.toString());
  }

  void diffActions(StringBuffer diffBuffer) {
    final int synthesizedActionMasked =
        getActionMasked(synthesizedEvent['action']);
    final int originalActionMasked = getActionMasked(originalEvent['action']);
    final String synthesizedActionName =
        getActionName(synthesizedActionMasked, synthesizedEvent['action']);
    final String originalActionName =
        getActionName(originalActionMasked, originalEvent['action']);

    if (synthesizedActionMasked != originalActionMasked)
      diffBuffer.write(
          'action (expected: $originalActionName actual: $synthesizedActionName) ');

    if (kPointerActions.contains(originalActionMasked) &&
        originalActionMasked == synthesizedActionMasked) {
      final int originalPointer = getPointerIdx(originalEvent['action']);
      final int synthesizedPointer = getPointerIdx(synthesizedEvent['action']);
      if (originalPointer != synthesizedPointer)
        diffBuffer.write(
            'pointerIdx (expected: $originalPointer actual: $synthesizedPointer action: $originalActionName ');
    }
  }

  void diffPointerProperties(StringBuffer diffBuffer) {
    final List<Map<dynamic, dynamic>> expectedList =
        originalEvent['pointerProperties'].cast<Map<dynamic, dynamic>>();
    final List<Map<dynamic, dynamic>> actualList =
        synthesizedEvent['pointerProperties'].cast<Map<dynamic, dynamic>>();

    if (expectedList.length != actualList.length) {
      diffBuffer.write(
          'pointerProperties (actual length: ${actualList.length}, expected length: ${expectedList.length} ');
      return;
    }

    for (int i = 0; i < expectedList.length; i++) {
      Map<String, dynamic> expected = expectedList[i].cast<String, dynamic>();
      Map<String, dynamic> actual = actualList[i].cast<String, dynamic>();
      diffMaps(expected, actual, diffBuffer,
          messagePrefix: '[pointerProperty $i] ');
    }
  }

  void diffPointerCoordsList(StringBuffer diffBuffer) {
    final List<Map<dynamic, dynamic>> expectedList =
        originalEvent['pointerCoords'].cast<Map<dynamic, dynamic>>();
    final List<Map<dynamic, dynamic>> actualList =
        synthesizedEvent['pointerCoords'].cast<Map<dynamic, dynamic>>();

    if (expectedList.length != actualList.length) {
      diffBuffer.write(
          'pointerCoords (actual length: ${actualList.length}, expected length: ${expectedList.length} ');
      return;
    }

    if (isSinglePointerAction(originalEvent['action'])) {
      final int idx = getPointerIdx(originalEvent['action']);
      final Map<String, dynamic> expected = expectedList[idx].cast<String, dynamic>();
      final Map<String, dynamic> actual = actualList[idx].cast<String, dynamic>();
      diffPointerCoords(expected, actual, idx, diffBuffer);
      // For POINTER_UP and POINTER_DOWN events the engine drops the data for all pointers
      // but for the pointer that was taken up/down.
      // See: https://github.com/flutter/flutter/issues/19882
      //
      // Until that issue is resolved, we only compare the pointer for which the action
      // applies to here.
      //
      // TODO(amirh): Compare all pointers once the issue mentioned above is resolved.
      return;
    }

    for (int i = 0; i < expectedList.length; i++) {
      final Map<String, dynamic> expected = expectedList[i].cast<String, dynamic>();
      final Map<String, dynamic> actual = actualList[i].cast<String, dynamic>();
      diffPointerCoords(expected, actual, i, diffBuffer);
    }
  }

  void diffPointerCoords(Map<String, dynamic> expected, Map<String, dynamic> actual, int pointerIdx,
      StringBuffer diffBuffer) {
    diffMaps(expected, actual, diffBuffer,
        messagePrefix: '[pointerCoord $pointerIdx] ',
        excludeKeys: <String>[
          'size', // Currently the framework doesn't get the size form the engine.
        ]);
  }

  static void diffMaps(Map<String, dynamic> expected,
      Map<String, dynamic> actual, StringBuffer diffBuffer,
      {List<String> excludeKeys = const <String>[],
      String messagePrefix = ''}) {
    const IterableEquality<String> eq = IterableEquality<String>();
    if (!eq.equals(expected.keys, actual.keys)) {
      diffBuffer.write(
          '${messagePrefix}keys (expected: ${expected.keys} actual: ${actual.keys} ');
      return;
    }
    for (String key in expected.keys) {
      if (excludeKeys.contains(key)) continue;
      if (doublesApproximatelyMatch(expected[key], actual[key])) continue;

      if (expected[key] != actual[key]) {
        diffBuffer.write(
            '$messagePrefix$key (expected: ${expected[key]} actual: ${actual[key]}) ');
      }
    }
  }

  static bool doublesApproximatelyMatch(dynamic a, dynamic b) =>
      a is double && b is double && (a - b).abs() < kDoubleErrorMargin;
}

bool isSinglePointerAction(int action) {
  final int actionMasked = getActionMasked(action);
  return actionMasked == 5 || // POINTER_DOWN
    actionMasked == 6; // POINTER_UP
}

int getActionMasked(int action) => action & 0xff;

int getPointerIdx(int action) => (action >> 8) & 0xff;

String getActionName(int actionMasked, int action) {
  const List<String> actionNames = <String>[
    'DOWN',
    'UP',
    'MOVE',
    'CANCEL',
    'OUTSIDE',
    'POINTER_DOWN',
    'POINTER_UP',
    'HOVER_MOVE',
    'SCROLL',
    'HOVER_ENTER',
    'HOVER_EXIT',
    'BUTTON_PRESS',
    'BUTTON_RELEASE'
  ];
  if (actionMasked < actionNames.length)
    return '${actionNames[actionMasked]}($action)';
  else
    return 'ACTION_$actionMasked';
}

