import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        return Container(
          height: 160,
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Filters',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (clip.filter != FilterType.none)
                      GestureDetector(
                        onTap: () => provider.updateClipFilter(
                            provider.selectedClipIndex, FilterType.none),
                        child: const Text('Remove',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: FilterType.values.length,
                  itemBuilder: (context, index) {
                    final filter = FilterType.values[index];
                    final isSelected = clip.filter == filter;

                    return GestureDetector(
                      onTap: () => provider.updateClipFilter(
                          provider.selectedClipIndex, filter),
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            // Filter preview square
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary, width: 2.5)
                                    : Border.all(
                                        color: AppColors.textTertiary,
                                        width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(
                                    _getFilterMatrix(filter),
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1E3A5F),
                                          Color(0xFF4A90D9),
                                          Color(0xFF7EC8E3),
                                        ],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.landscape,
                                          color: Colors.white60, size: 28),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _filterName(filter),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

  List<double> _getFilterMatrix(FilterType filter) {
    switch (filter) {
      case FilterType.blackAndWhite:
        return [
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.sepia:
        return [
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.vivid:
        return [
          1.2, 0, 0, 0, 0,
          0, 1.2, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.cool:
        return [
          0.8, 0, 0.1, 0, 0,
          0, 0.9, 0.1, 0, 0,
          0.1, 0.1, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.warm:
        return [
          1.2, 0.1, 0, 0, 0,
          0.1, 1.0, 0, 0, 0,
          0, 0, 0.8, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.fade:
        return [
          0.8, 0, 0, 0, 0.1,
          0, 0.8, 0, 0, 0.1,
          0, 0, 0.8, 0, 0.1,
          0, 0, 0, 1, 0,
        ];
      case FilterType.vintage:
        return [
          0.9, 0.2, 0.1, 0, 0,
          0.2, 0.8, 0.1, 0, 0,
          0.1, 0.1, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ];
      default:
        return [
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ];
    }
  }

  String _filterName(FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return 'Original';
      case FilterType.vintage:
        return 'Vintage';
      case FilterType.blackAndWhite:
        return 'B&W';
      case FilterType.sepia:
        return 'Sepia';
      case FilterType.vivid:
        return 'Vivid';
      case FilterType.cool:
        return 'Cool';
      case FilterType.warm:
        return 'Warm';
      case FilterType.fade:
        return 'Fade';
      case FilterType.chrome:
        return 'Chrome';
      case FilterType.dark:
        return 'Dark';
      case FilterType.light:
        return 'Light';
      case FilterType.rose:
        return 'Rose';
      case FilterType.ocean:
        return 'Ocean';
      case FilterType.forest:
        return 'Forest';
      case FilterType.sunset:
        return 'Sunset';
      case FilterType.neon:
        return 'Neon';
      case FilterType.cinema:
        return 'Cinema';
      case FilterType.portrait:
        return 'Portrait';
      case FilterType.food:
        return 'Food';
      case FilterType.travel:
        return 'Travel';
    }
  }
}
