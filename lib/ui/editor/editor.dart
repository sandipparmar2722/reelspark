// ============================================================================
// EDITOR MODULE - CENTRAL EXPORT
// ============================================================================
// This file provides a single import point for all editor components
//
// Usage: import 'package:reelspark/ui/editor/editor.dart';
//
// This gives you access to:
// - All Flutter/Dart core libraries
// - All third-party packages
// - All models, services, utils
// - All editor components

// ============================================================================
// CENTRAL IMPORTS (includes all dependencies)
// ============================================================================

// Dart Core
export 'dart:async';
export 'dart:io';
export 'dart:math' show atan2, pi;

// Flutter
export 'package:flutter/material.dart';

// Third-Party Packages
export 'package:file_picker/file_picker.dart';
export 'package:audioplayers/audioplayers.dart';
export 'package:image_picker/image_picker.dart';
export 'package:media_store_plus/media_store_plus.dart';
export 'package:permission_handler/permission_handler.dart';

// Models
export 'package:reelspark/models/audio_clip.dart';
export 'package:reelspark/models/text_clip.dart';
export 'package:reelspark/models/filter_clip.dart';

// Services
export 'package:reelspark/services/New Project/video_service.dart';

// Utils
export 'package:reelspark/utils/time_utils.dart';

// ============================================================================
// MAIN SCREEN
// ============================================================================
export 'editor_screen.dart';

// ============================================================================
// STATE MANAGEMENT
// ============================================================================
export 'state/editor_state.dart';
export 'state/text_state.dart';
export 'state/audio_state.dart';
export 'state/filter_state.dart';

// ============================================================================
// PREVIEW COMPONENTS
// ============================================================================
export 'preview/preview_area.dart';
export 'preview/image_layer.dart';
export 'preview/text_layer.dart';

// ============================================================================
// TIMELINE COMPONENTS
// ============================================================================
export 'timeline/timeline_container.dart';
export 'timeline/video_timeline.dart';
export 'timeline/text_timeline.dart';
export 'timeline/audio_timeline.dart';

// ============================================================================
// PANEL COMPONENTS
// ============================================================================
export 'panels/text_panel.dart';
export 'panels/audio_panel.dart';
export 'panels/effects_panel.dart';
export 'panels/filter_panel.dart';

// ============================================================================
// WIDGET COMPONENTS
// ============================================================================
export 'widgets/editor_top_bar.dart';
export 'widgets/editor_bottom_bar.dart';
export 'widgets/rotate_scale_handle.dart';
export 'widgets/control_button.dart';

// ============================================================================
// IMPORTANT: Use this single import in all editor files
// ============================================================================
// import 'package:reelspark/ui/editor/editor.dart';
// This gives you access to everything you need!

export '../../models/clip_transition.dart';

export 'package:reelspark/ui/editor/editor.dart';
export 'package:reelspark/ui/editor/transition/transition_picker.dart';

export '../../models/effect_clip.dart';

export 'dart:io';
export 'package:flutter/material.dart';
export 'package:image_picker/image_picker.dart';
export 'package:permission_handler/permission_handler.dart';
export 'package:reelspark/ui/editor/editor.dart';