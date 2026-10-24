import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';

class TextOverlayPanel extends StatefulWidget {
  const TextOverlayPanel({super.key});

  @override
  State<TextOverlayPanel> createState() => _TextOverlayPanelState();
}

class _TextOverlayPanelState extends State<TextOverlayPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  Color _textColor = Colors.white;
  Color? _bgColor;
  double _fontSize = 24;
  String _fontFamily = 'Roboto';
  FontWeight _fontWeight = FontWeight.bold;
  TextAnimationType _animIn = TextAnimationType.fadeIn;
  TextAnimationType _animOut = TextAnimationType.fadeOut;
  bool _hasShadow = false;
  bool _hasStroke = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        return Container(
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Text'),
                  Tab(text: 'Style'),
                  Tab(text: 'Animation'),
                ],
              ),
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── TEXT TAB ───────────────────────────────────────────────
                    _TextTab(
                      controller: _textController,
                      onAdd: () => _addText(context, provider, clip),
                      overlays: clip.textOverlays,
                      onEdit: (i) {
                        setState(() {
                          _editingIndex = i;
                          _textController.text = clip.textOverlays[i].text;
                          _textColor = clip.textOverlays[i].textColor;
                          _fontSize = clip.textOverlays[i].fontSize;
                          _fontFamily = clip.textOverlays[i].fontFamily;
                        });
                      },
                      onRemove: (i) => provider.removeTextOverlay(
                          provider.selectedClipIndex, i),
                    ),
                    // ── STYLE TAB ──────────────────────────────────────────────
                    _StyleTab(
                      textColor: _textColor,
                      bgColor: _bgColor,
                      fontSize: _fontSize,
                      fontFamily: _fontFamily,
                      fontWeight: _fontWeight,
                      hasShadow: _hasShadow,
                      hasStroke: _hasStroke,
                      onColorChanged: (c) =>
                          setState(() => _textColor = c),
                      onBgColorChanged: (c) =>
                          setState(() => _bgColor = c),
                      onFontSizeChanged: (s) =>
                          setState(() => _fontSize = s),
                      onFontFamilyChanged: (f) =>
                          setState(() => _fontFamily = f),
                      onFontWeightChanged: (w) =>
                          setState(() => _fontWeight = w),
                      onShadowToggled: () =>
                          setState(() => _hasShadow = !_hasShadow),
                      onStrokeToggled: () =>
                          setState(() => _hasStroke = !_hasStroke),
                    ),
                    // ── ANIMATION TAB ──────────────────────────────────────────
                    _AnimationTab(
                      animIn: _animIn,
                      animOut: _animOut,
                      onAnimInChanged: (a) =>
                          setState(() => _animIn = a),
                      onAnimOutChanged: (a) =>
                          setState(() => _animOut = a),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addText(
      BuildContext context, EditorProvider provider, VideoClip clip) {
    if (_textController.text.isEmpty) return;

    final overlay = TextOverlay(
      id: const Uuid().v4(),
      text: _textController.text,
      textColor: _textColor,
      backgroundColor: _bgColor,
      fontSize: _fontSize,
      fontFamily: _fontFamily,
      fontWeight: _fontWeight,
      animationIn: _animIn,
      animationOut: _animOut,
      hasShadow: _hasShadow,
      hasStroke: _hasStroke,
      startTime: provider.playheadPosition,
      endTime: provider.playheadPosition + const Duration(seconds: 3),
    );

    if (_editingIndex != null) {
      provider.updateTextOverlay(
          provider.selectedClipIndex, _editingIndex!, overlay);
      _editingIndex = null;
    } else {
      provider.addTextOverlay(provider.selectedClipIndex, overlay);
    }
    _textController.clear();
  }
}

class _TextTab extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final List<TextOverlay> overlays;
  final Function(int) onEdit;
  final Function(int) onRemove;

  const _TextTab({
    required this.controller,
    required this.onAdd,
    required this.overlays,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter text…',
                    hintStyle: const TextStyle(
                        color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Overlay list
          ...overlays.asMap().entries.map((entry) => _OverlayItem(
                overlay: entry.value,
                onEdit: () => onEdit(entry.key),
                onRemove: () => onRemove(entry.key),
              )),
        ],
      ),
    );
  }
}

class _OverlayItem extends StatelessWidget {
  final TextOverlay overlay;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _OverlayItem({
    required this.overlay,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              overlay.text,
              style: TextStyle(
                color: overlay.textColor,
                fontSize: 13,
                fontWeight: overlay.fontWeight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: AppColors.textSecondary,
                size: 16),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            onPressed: onRemove,
            icon:
                const Icon(Icons.delete, color: AppColors.primary, size: 16),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}

class _StyleTab extends StatelessWidget {
  final Color textColor;
  final Color? bgColor;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool hasShadow;
  final bool hasStroke;
  final Function(Color) onColorChanged;
  final Function(Color?) onBgColorChanged;
  final Function(double) onFontSizeChanged;
  final Function(String) onFontFamilyChanged;
  final Function(FontWeight) onFontWeightChanged;
  final VoidCallback onShadowToggled;
  final VoidCallback onStrokeToggled;

  const _StyleTab({
    required this.textColor,
    required this.bgColor,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.hasShadow,
    required this.hasStroke,
    required this.onColorChanged,
    required this.onBgColorChanged,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onFontWeightChanged,
    required this.onShadowToggled,
    required this.onStrokeToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color row
          Row(
            children: [
              _ColorButton(
                label: 'Text',
                color: textColor,
                onTap: () => _pickColor(context, textColor, onColorChanged),
              ),
              const SizedBox(width: 12),
              _ColorButton(
                label: 'BG',
                color: bgColor ?? Colors.transparent,
                onTap: () => _pickColor(
                    context, bgColor ?? Colors.transparent, (c) {
                  onBgColorChanged(c == Colors.transparent ? null : c);
                }),
              ),
              const SizedBox(width: 16),
              // Font size
              const Text('Size',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: Slider(
                  value: fontSize.clamp(8.0, 80.0),
                  min: 8,
                  max: 80,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceVariant,
                  onChanged: onFontSizeChanged,
                ),
              ),
              Text(
                fontSize.toStringAsFixed(0),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Font family
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: AppConstants.fontFamilies.map((f) {
                return GestureDetector(
                  onTap: () => onFontFamilyChanged(f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fontFamily == f
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: fontFamily == f
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: f,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Bold/Shadow/Stroke toggles
          Row(
            children: [
              _ToggleChip(
                label: 'Bold',
                isActive: fontWeight == FontWeight.bold,
                onTap: () => onFontWeightChanged(
                  fontWeight == FontWeight.bold
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Shadow',
                isActive: hasShadow,
                onTap: onShadowToggled,
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Stroke',
                isActive: hasStroke,
                onTap: onStrokeToggled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickColor(
      BuildContext context, Color initial, Function(Color) onPick) {
    Color picked = initial;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Pick Color',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initial,
            onColorChanged: (c) => picked = c,
            enableAlpha: true,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onPick(picked);
              Navigator.pop(context);
            },
            child: const Text('Done',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _AnimationTab extends StatelessWidget {
  final TextAnimationType animIn;
  final TextAnimationType animOut;
  final Function(TextAnimationType) onAnimInChanged;
  final Function(TextAnimationType) onAnimOutChanged;

  const _AnimationTab({
    required this.animIn,
    required this.animOut,
    required this.onAnimInChanged,
    required this.onAnimOutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Animate In',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TextAnimationType.values.map((a) {
              return GestureDetector(
                onTap: () => onAnimInChanged(a),
                child: _AnimChip(
                    label: _animName(a), isSelected: animIn == a),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Animate Out',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TextAnimationType.values.map((a) {
              return GestureDetector(
                onTap: () => onAnimOutChanged(a),
                child: _AnimChip(
                    label: _animName(a), isSelected: animOut == a),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _animName(TextAnimationType a) {
    switch (a) {
      case TextAnimationType.none:
        return 'None';
      case TextAnimationType.fadeIn:
        return 'Fade';
      case TextAnimationType.fadeOut:
        return 'Fade Out';
      case TextAnimationType.slideFromLeft:
        return '← Slide';
      case TextAnimationType.slideFromRight:
        return '→ Slide';
      case TextAnimationType.slideFromTop:
        return '↑ Slide';
      case TextAnimationType.slideFromBottom:
        return '↓ Slide';
      case TextAnimationType.typewriter:
        return 'Typewriter';
      case TextAnimationType.bounce:
        return 'Bounce';
      case TextAnimationType.zoom:
        return 'Zoom';
      case TextAnimationType.shake:
        return 'Shake';
    }
  }
}

class _ColorButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AnimChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _AnimChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
