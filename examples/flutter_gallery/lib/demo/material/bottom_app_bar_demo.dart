// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class BottomAppBarDemo extends StatefulWidget {
  static const String routeName = '/material/bottom_app_bar';

  @override
  State createState() => new BottomAppBarDemoState();
}

enum BabMode {
  RIGHT_FAB,
  CENTER_FAB
}

class BottomAppBarDemoState extends State<BottomAppBarDemo> {

  int fabIdx = 0;

  List<List<dynamic>> fabs = <List<dynamic>> [
    <dynamic> [
      'None',
      null
    ],
    <dynamic> [
      'Circular',
      const FloatingActionButton(
        onPressed: null,
        child: const Icon(Icons.add),
      )
    ],
    <dynamic> [
      'Diamond',
      const DiamondFab(
        child: const Icon(Icons.add),
      )
    ],
  ];

  int babModeIdx = 0;

  List<List<dynamic>> babModes = <List<dynamic>> [
    <dynamic> [
      'Right aligned floating action button',
      BabMode.RIGHT_FAB
    ],
    <dynamic> [
      'Center aligned floating action button',
      BabMode.CENTER_FAB
    ],
  ];

  List<Color> babColors = <Color> [
    null,
    Colors.orange,
    Colors.green,
    Colors.lightBlue,
  ];

  Color babColor;

  bool notchEnabled = true;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Bottom app bar demo')
      ),
      body: new Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: controls(context),
      ),
      bottomNavigationBar: new MyBottomAppBar(babModes[babModeIdx][1], babColor, notchEnabled),
      floatingActionButton: fabs[fabIdx][1],
    );
  }

  Widget controls(BuildContext context) {
    return new Column(
      children: <Widget> [
        new Text(
          'Floating action button',
          style: Theme.of(context).textTheme.title,
        ),
        fabOptions(),
        const Divider(),
        new Text(
          'Bottom app bar mode',
          style: Theme.of(context).textTheme.title,
        ),
        babConfigModes(),
        const Divider(),
        new Text(
          'Bottom app bar options',
          style: Theme.of(context).textTheme.title,
        ),
        babColorSelection(),
        new CheckboxListTile(
          title: const Text('Enable notch'),
          value: notchEnabled,
          onChanged: (bool value) { setState(() { notchEnabled = value; }); },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget fabOptions() {
    final List<Widget> options = <Widget>[];
    for (int i = 0; i < fabs.length; i++) {
      final List<dynamic> fabConfig = fabs[i];
      options.add(
        new RadioListTile<int>(
          title: new Text(fabConfig[0]),
          value: i,
          groupValue: fabIdx,
          onChanged: (int newIdx) { setState(() { fabIdx = newIdx; }); },
        )
      );
    }
    return new Column(children: options);
  }

  Widget babConfigModes() {
    final List<Widget> modes = <Widget> [];
    for (int i = 0; i < babModes.length; i++) {
      final List<dynamic> babConfig = babModes[i];
      modes.add(
        new RadioListTile<int>(
          title: new Text(babConfig[0]),
          value: i,
          groupValue: babModeIdx,
          onChanged: (int newIdx) { setState(() { babModeIdx = newIdx; }); },
        )
      );
    }
    return new Column(children: modes);
  }

  Widget babColorSelection() {
    final List<Widget> colors = <Widget> [
      new Text('Color:'),
    ];
    babColors.forEach((Color color) {
      colors.add(
        new Radio(
          value: color,
          groupValue: babColor,
          onChanged: (Color color) { setState(() { babColor = color; }); },
        )
      );
      colors.add(new Container(
          decoration: new BoxDecoration(
            color: color,
            border: new Border.all(width:2.0, color: Colors.black),
          ),
          child: const SizedBox(width: 20.0, height: 20.0)
      ));
      colors.add(const Padding(padding: const EdgeInsets.only(left: 12.0)));
    });
    return new Row(
      children: colors,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}

class MyBottomAppBar extends StatelessWidget {
  const MyBottomAppBar(this.babMode, this.color, this.enableNotch);

  final BabMode babMode;
  final Color color;
  final bool enableNotch;

  final Curve fadeOutCurve = const Interval(0.0, 0.3333);
  final Curve fadeInCurve = const Interval(0.3333, 1.0);

  @override
  Widget build(BuildContext context) {
    final bool showsFirst = babMode == BabMode.RIGHT_FAB;
    return new BottomAppBar(
      color: color,
      hasNotch: enableNotch,
      child: new Row(
        children: <Widget> [
          new IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              showModalBottomSheet<Null>(context: context, builder: (BuildContext context) => const MyDrawer()); },
          ),
          new Expanded(
            child: new AnimatedCrossFade(
              duration: const Duration(milliseconds: 225),
              firstChild: babContents(context, BabMode.RIGHT_FAB),
              firstCurve: showsFirst ? fadeOutCurve  : fadeInCurve,
              secondChild: babContents(context, BabMode.CENTER_FAB),
              secondCurve: showsFirst ? fadeInCurve  : fadeOutCurve,
              crossFadeState: showsFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            ),
          ),
        ],
      ),
    );
  }

  Widget babContents(BuildContext context, BabMode babMode) {
    final List<Widget> rowContents = <Widget> [];
    if (babMode == BabMode.CENTER_FAB) {
      rowContents.add(
        new Expanded(
          child: new
          ConstrainedBox(
            constraints:
            const BoxConstraints(maxHeight: 0.0),
          ),
        ),
      );
    }
    rowContents.addAll(<Widget> [
      new IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {},
      ),
      new IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {},
      )
    ]);
    return new Row(
      children: rowContents
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer();

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new Column(
        children: <Widget> [
          const ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
          ),
          const ListTile(
            leading: const Icon(Icons.threed_rotation),
            title: const Text('3D'),
          ),
        ],
      ),
    );
  }
}

class DiamondFab extends StatefulWidget {
  const DiamondFab({
    this.child,
    this.notchMargin: 6.0,
  });

  final Widget child;
  final double notchMargin;

  @override
  State createState() => new DiamondFabState();
}

class DiamondFabState extends State<DiamondFab> {

  VoidCallback _clearComputeNotch;

  @override
  Widget build(BuildContext context) {
    return new Material(
      shape: const DiamondBorder(),
      color: Theme.of(context).accentColor,
      child: new Container(
        width: 56.0,
        height: 56.0,
        child: IconTheme.merge(
          data: new IconThemeData(color: Theme.of(context).accentIconTheme.color),
          child: widget.child,
        ),
      ),
      elevation: 6.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clearComputeNotch = Scaffold.setFloatingActionButtonNotchFor(context, _computeNotch);
  }

  @override
  void deactivate() {
    if (_clearComputeNotch != null)
      _clearComputeNotch();
    super.deactivate();
  }

  Path _computeNotch(Rect host, Rect guest, Offset start, Offset end) {
    final Rect marginedGuest = guest.inflate(widget.notchMargin);
    if (!host.overlaps(marginedGuest))
      return new Path()..lineTo(end.dx, end.dy);

    final Rect intersection = marginedGuest.intersect(host);
    // We are computing a "V" shaped notch, as in this diagram:
    //    -----\****   /-----
    //          \     /
    //           \   /
    //            \ /
    //
    //  "-" marks the top edge of the bottom app bar.
    //  "\" and "/" marks the notch outline
    //
    //  notchToCenter is the horizontal distance between the guest's center and
    //  the host's top edge where the notch starts (marked with "*").
    //  We compute notchToCenter by similar triangles:
    final double notchToCenter =
      intersection.height * (marginedGuest.height / 2.0)
      / (marginedGuest.width / 2.0);

    return new Path()
      ..lineTo(marginedGuest.center.dx - notchToCenter, host.top)
      ..lineTo(marginedGuest.left + marginedGuest.width / 2.0, marginedGuest.bottom)
      ..lineTo(marginedGuest.center.dx + notchToCenter, host.top)
      ..lineTo(end.dx, end.dy);
  }
}

class DiamondBorder extends ShapeBorder {
  const DiamondBorder();

  @override
  EdgeInsetsGeometry get dimensions {
    return const EdgeInsets.only();
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..moveTo(rect.left + rect.width / 2.0, rect.top)
      ..lineTo(rect.right, rect.top + rect.height / 2.0)
      ..lineTo(rect.left + rect.width  / 2.0, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height / 2.0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {}
}
