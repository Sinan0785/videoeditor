import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/project_model.dart';
import '../utils/constants.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textSecondary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Export',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),
          body: provider.exportState == ExportState.processing
              ? _ExportProgress(provider: provider)
              : provider.exportState == ExportState.success
                  ? _ExportSuccess(
                      filePath: provider.exportFilePath ?? '',
                      onBack: () {
                        provider.resetExport();
                        Navigator.pop(context);
                      },
                    )
                  : _ExportSettings(provider: provider),
        );
      },
    );
  }
}

// ── EXPORT SETTINGS ────────────────────────────────────────────────────────────

class _ExportSettings extends StatelessWidget {
  final EditorProvider provider;

  const _ExportSettings({required this.provider});

  @override
  Widget build(BuildContext context) {
    final project = provider.project;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Preview summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.movie, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '${project.clips.length} clip${project.clips.length == 1 ? '' : 's'} · ${_formatDuration(project.computedDuration)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _SectionTitle(title: 'Resolution'),
        _OptionGrid<ExportResolution>(
          options: ExportResolution.values,
          selected: project.resolution,
          labelBuilder: (r) {
            switch (r) {
              case ExportResolution.hd480:
                return '480p';
              case ExportResolution.hd720:
                return '720p';
              case ExportResolution.hd1080:
                return '1080p';
              case ExportResolution.uhd4k:
                return '4K';
            }
          },
          subLabelBuilder: (r) {
            switch (r) {
              case ExportResolution.hd480:
                return '640×480';
              case ExportResolution.hd720:
                return '1280×720';
              case ExportResolution.hd1080:
                return '1920×1080';
              case ExportResolution.uhd4k:
                return '3840×2160';
            }
          },
          onChanged: (r) =>
              provider.updateProjectResolution(r),
        ),

        const SizedBox(height: 20),

        _SectionTitle(title: 'Quality'),
        _OptionGrid<ExportQuality>(
          options: ExportQuality.values,
          selected: project.quality,
          labelBuilder: (q) {
            switch (q) {
              case ExportQuality.low:
                return 'Low';
              case ExportQuality.medium:
                return 'Medium';
              case ExportQuality.high:
                return 'High';
              case ExportQuality.veryHigh:
                return 'Very High';
            }
          },
          subLabelBuilder: (q) {
            switch (q) {
              case ExportQuality.low:
                return 'Smaller file';
              case ExportQuality.medium:
                return 'Balanced';
              case ExportQuality.high:
                return 'Good quality';
              case ExportQuality.veryHigh:
                return 'Best quality';
            }
          },
          onChanged: (q) =>
              provider.updateProjectQuality(q),
        ),

        const SizedBox(height: 20),

        _SectionTitle(title: 'Frame Rate'),
        Row(
          children: [24, 30, 60].map((fps) {
            final isSelected = project.fps == fps;
            return Expanded(
              child: GestureDetector(
                onTap: () => provider.updateProjectFps(fps),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text('$fps',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      Text('fps',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.7)
                                : AppColors.textTertiary,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Estimated file size
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.storage, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              const Text('Estimated size',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(
                _estimatedSize(project),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        if (provider.exportState == ExportState.error) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.exportError ?? 'Export failed',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Export button
        GestureDetector(
          onTap: () async {
            await provider.exportVideo();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_download, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Export Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _estimatedSize(project) {
    final secs = project.computedDuration.inSeconds;
    final bitrateKbps = {
      ExportResolution.hd480: 1000,
      ExportResolution.hd720: 2500,
      ExportResolution.hd1080: 5000,
      ExportResolution.uhd4k: 20000,
    }[project.resolution]!;
    final qualityMult = {
      ExportQuality.low: 0.5,
      ExportQuality.medium: 0.75,
      ExportQuality.high: 1.0,
      ExportQuality.veryHigh: 1.4,
    }[project.quality]!;
    final mb = (secs * bitrateKbps * qualityMult) / 8 / 1024;
    if (mb < 1024) return '~${mb.toStringAsFixed(0)} MB';
    return '~${(mb / 1024).toStringAsFixed(1)} GB';
  }
}

// ── EXPORT PROGRESS ────────────────────────────────────────────────────────────

class _ExportProgress extends StatelessWidget {
  final EditorProvider provider;

  const _ExportProgress({required this.provider});

  @override
  Widget build(BuildContext context) {
    final progress = provider.exportProgress;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated circle
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Exporting video...',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please keep the app open',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── EXPORT SUCCESS ─────────────────────────────────────────────────────────────

class _ExportSuccess extends StatelessWidget {
  final String filePath;
  final VoidCallback onBack;

  const _ExportSuccess({required this.filePath, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.accentGreen, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Export Complete!',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your video has been saved to Gallery',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              filePath.split('/').last,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textTertiary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Editor',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Share intent
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share, size: 18, color: Colors.white),
                    label: const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── HELPERS ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _OptionGrid<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final String Function(T) subLabelBuilder;
  final Function(T) onChanged;

  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.subLabelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: options.length,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) {
        final opt = options[i];
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  labelBuilder(opt),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabelBuilder(opt),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.7)
                        : AppColors.textTertiary,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
