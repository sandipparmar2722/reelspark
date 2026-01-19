import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Renders a widget tree offscreen into an image.
///
/// This avoids attaching to the current screen's pipeline/overlay and prevents
/// `RenderRepaintBoundary.toImage` assertions like `!debugNeedsPaint`.
class OffscreenWidgetRenderer {
  static Future<ui.Image> renderToImage({
    required Widget widget,
    required Size size,
    double pixelRatio = 1.0,
  }) async {
    final repaintBoundary = RenderRepaintBoundary();

    final view = WidgetsBinding.instance.platformDispatcher.views.first;

    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final renderObjectToWidgetAdapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: widget,
        ),
      ),
    );

    final rootElement = renderObjectToWidgetAdapter.attachToRenderTree(buildOwner);

    // Allow a microtask to settle any pending image loads.
    await Future<void>.delayed(Duration.zero);

    buildOwner
      ..buildScope(rootElement)
      ..finalizeTree();

    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    // Wait for next frame to ensure paint is complete.
    await SchedulerBinding.instance.endOfFrame;

    try {
      final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      return image;
    } catch (e) {
      // If toImage fails (e.g., debugNeedsPaint), try one more layout pass.
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      await SchedulerBinding.instance.endOfFrame;

      return repaintBoundary.toImage(pixelRatio: pixelRatio);
    }
  }
}
