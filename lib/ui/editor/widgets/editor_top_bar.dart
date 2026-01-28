import 'package:reelspark/ui/editor/editor.dart';

/// A CapCut-inspired top bar with:
/// - Left: Back button
/// - Center: Resolution dropdown (e.g., "AI Ultra HD")
/// - Right: Rounded blue "Export" button
///
/// This bar is designed to sit at the top of the editor screen,
/// providing quick access to export and navigation.
class EditorTopBar extends StatelessWidget {
  // --- Callbacks ---
  final VoidCallback onBack;
  final VoidCallback onExport;
  final VoidCallback? onResolutionTap;

  // --- State ---
  final bool isExporting;
  final String resolution;

  const EditorTopBar({
    super.key,
    required this.onBack,
    required this.onExport,
    this.onResolutionTap,
    this.isExporting = false,
    this.resolution = 'AI Ultra HD',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // LEFT: Back Button
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Close',
              ),

              const Spacer(),

              // CENTER: Resolution Dropdown
              GestureDetector(
                onTap: onResolutionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        resolution,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // RIGHT: Export Button
              _buildExportButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: isExporting ? null : onExport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isExporting
                ? [Colors.grey.shade700, Colors.grey.shade600]
                : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isExporting
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExporting) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isExporting ? 'Exporting...' : 'Export',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


