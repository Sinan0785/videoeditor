import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';

class StickerPanel extends StatefulWidget {
  const StickerPanel({super.key});

  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel> {
  String _selectedCategory = 'Emoji';

  static const _categories = [
    'Emoji',
    'Shapes',
    'Arrows',
    'Hearts',
    'Stars',
    'Badges',
    'Text Art',
  ];

  static const _emojiStickers = [
    '😀','😂','🥹','😍','🤩','😎','🥳','🤔','😴','🤯',
    '👍','👏','🙌','✌️','🤟','🫶','💪','🫂','🤝','👋',
    '🔥','⚡','💥','✨','🌟','💫','🎉','🎊','🎈','🎁',
    '❤️','💕','💖','💯','🏆','👑','💎','🌈','🦋','🌸',
  ];

  static const _shapeStickers = [
    '⬛','⬜','🟥','🟦','🟨','🟩','🟧','🟪',
    '🔴','🔵','🟤','⚫','⚪','🟡','🟢','🔶',
    '🔷','🔸','🔹','💠','🔲','🔳','▪️','▫️',
  ];

  static const _arrowStickers = [
    '➡️','⬅️','⬆️','⬇️','↗️','↘️','↙️','↖️',
    '↕️','↔️','🔄','🔃','⤴️','⤵️','🔁','🔂',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        return Container(
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category row
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Sticker grid
              SizedBox(
                height: 190,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _currentStickers.length,
                  itemBuilder: (context, i) {
                    final sticker = _currentStickers[i];
                    return GestureDetector(
                      onTap: () => _addSticker(context, provider, sticker),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(sticker,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> get _currentStickers {
    switch (_selectedCategory) {
      case 'Shapes':
        return _shapeStickers;
      case 'Arrows':
        return _arrowStickers;
      default:
        return _emojiStickers;
    }
  }

  void _addSticker(
      BuildContext context, EditorProvider provider, String emoji) {
    if (provider.selectedClipIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a clip first')),
      );
      return;
    }

    final sticker = StickerOverlay(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assetPath: emoji,
      position: const Offset(0.5, 0.5),
      rotation: 0,
      scale: 1.0,
      startTime: provider.playheadPosition,
      endTime: provider.playheadPosition + const Duration(seconds: 3),
      opacity: 1.0,
    );

    provider.addStickerOverlay(provider.selectedClipIndex, sticker);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji sticker added'),
        duration: AppConstants.snackbarDuration,
      ),
    );
  }
}
