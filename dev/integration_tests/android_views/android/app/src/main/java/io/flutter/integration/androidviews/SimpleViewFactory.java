package io.flutter.integration.androidviews;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class SimpleViewFactory implements PlatformViewFactory {
    final BinaryMessenger messenger;

    public SimpleViewFactory(BinaryMessenger messenger) {
        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int id) {
        MethodChannel methodChannel = new MethodChannel(messenger, "simple_view/" + id);
        return new SimplePlatformView(context, methodChannel);
    }
}
