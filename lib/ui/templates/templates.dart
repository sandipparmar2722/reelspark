/// Templates feature module (barrel export).
///
/// This folder implements the end-to-end "video templates" flow:
///
/// 1) Load template definitions from JSON assets via [TemplateRepository].
/// 2) Show templates grid + categories via [TemplatesHomeScreen].
/// 3) Watch template preview video/music via [TemplateDetailScreen].
/// 4) Select photos, optionally preview live (no FFmpeg).
/// 5) Render/export a final MP4 via [TemplateRenderService] + FFmpeg.
///
/// Importing `templates.dart` lets other features access the public surface
/// without needing to know individual file paths.

// Core data & models
export 'data/template_repository.dart';
export 'models/video_template.dart';

// Services
export 'services/timeline_controller.dart';

// Screens
export 'screens/templates_home_screen.dart';
export 'screens/template_detail_screen.dart';
export 'screens/template_editor_screen.dart';
export 'screens/template_export_screen.dart';
export 'screens/template_rendering_screen.dart';

// Widgets
export 'widgets/template_card.dart';

// Dart libraries
export 'dart:convert';
export 'dart:io';

// Flutter packages
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';



// Third-party packages
export 'package:file_picker/file_picker.dart';
export 'package:image_picker/image_picker.dart';
export 'package:just_audio/just_audio.dart';
export 'package:video_player/video_player.dart';

export 'package:permission_handler/permission_handler.dart';
export 'package:share_plus/share_plus.dart';
export 'package:reelspark/ui/templates/screens/template_live_preview_screen.dart';