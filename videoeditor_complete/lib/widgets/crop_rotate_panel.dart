import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';

class CropRotatePanel extends StatefulWidget {
  final bool isCrop;

  const CropRotatePanel({super.key, this.isCrop = true});

  @override
  State<CropRotatePanel> createState() => _CropRotatePanelState();
}

class _CropRotatePanelState extends State<CropRotatePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _rotation = 0;
  bool _flipH = false;
  bool _flipV = false;
  String _selectedRatio = 'Free';

  static const _ratios = ['Free', 'Original', '9:16', '16:9', '1:1', '4:5', '3:4', '2:3'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (!widget.isCrop) _tabController.index = 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Crop'),
                  Tab(text: 'Rotate & Flip'),
                ],
              ),
              SizedBox(
                height: 220,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── CROP ──────────────────────────────────────────────────
                    _CropTab(
                      selectedRatio: _selectedRatio,
                      onRatioChanged: (r) => setState(() => _selectedRatio = r),
                      ratios: _ratios,
                    ),
                    // ── ROTATE & FLIP ─────────────────────────────────────────
                    _RotateFlipTab(
                      rotation: clip.rotation.toDouble(),
                      flipH: _flipH,
                      flipV: _flipV,
                      onRotate90: () {
                        final newRotation = ((clip.rotation + 90) % 360);
                        provider.updateClipRotation(
                            provider.selectedClipIndex, newRotation);
                      },
                      onRotateMinus90: () {
                        final newRotation =
                            ((clip.rotation - 90 + 360) % 360);
                        provider.updateClipRotation(
                            provider.selectedClipIndex, newRotation);
                      },
                      onFlipH: () {
                        setState(() => _flipH = !_flipH);
                      },
                      onFlipV: () {
                        setState(() => _flipV = !_flipV);
                      },
                      onFineRotation: (val) {
                        setState(() => _rotation = val);
                        provider.updateClipRotation(
                            provider.selectedClipIndex, val.round());
                      },
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
}

class _CropTab extends StatelessWidget {
  final String selectedRatio;
  final Function(String) onRatioChanged;
  final List<String> ratios;

  const _CropTab({
    required this.selectedRatio,
    required this.onRatioChanged,
    required this.ratios,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Aspect ratio selector
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: ratios.length,
            itemBuilder: (context, i) {
              final ratio = ratios[i];
              final isSelected = ratio == selectedRatio;
              return GestureDetector(
                onTap: () => onRatioChanged(ratio),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.textTertiary),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ratio,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Crop preview area
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Grid overlay
                  CustomPaint(
                    painter: _CropGridPainter(),
                    child: Container(),
                  ),
                  // Handles
                  Positioned(
                    top: 0, left: 0,
                    child: _CropHandle(onDrag: (_, __) {}),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: _CropHandle(onDrag: (_, __) {}),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: _CropHandle(onDrag: (_, __) {}),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: _CropHandle(onDrag: (_, __) {}),
                  ),
                  const Center(
                    child: Icon(Icons.crop, color: Colors.white30, size: 40),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;
    // 3x3 grid
    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3),
        Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), paint);
    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CropHandle extends StatelessWidget {
  final Function(double, double) onDrag;

  const _CropHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => onDrag(d.delta.dx, d.delta.dy),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}

class _RotateFlipTab extends StatelessWidget {
  final double rotation;
  final bool flipH;
  final bool flipV;
  final VoidCallback onRotate90;
  final VoidCallback onRotateMinus90;
  final VoidCallback onFlipH;
  final VoidCallback onFlipV;
  final Function(double) onFineRotation;

  const _RotateFlipTab({
    required this.rotation,
    required this.flipH,
    required this.flipV,
    required this.onRotate90,
    required this.onRotateMinus90,
    required this.onFlipH,
    required this.onFlipV,
    required this.onFineRotation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick rotation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.rotate_left,
                label: 'Rotate Left',
                onTap: onRotateMinus90,
              ),
              _ActionButton(
                icon: Icons.rotate_right,
                label: 'Rotate Right',
                onTap: onRotate90,
              ),
              _ActionButton(
                icon: Icons.flip,
                label: 'Flip H',
                active: flipH,
                onTap: onFlipH,
              ),
              _ActionButton(
                icon: Icons.flip,
                label: 'Flip V',
                active: flipV,
                onTap: onFlipV,
                iconRotation: 90 * (3.1415926 / 180),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Current rotation display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rotate_right,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${rotation.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fine rotation slider
          Row(
            children: [
              const Text('-180°',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 10)),
              Expanded(
                child: Slider(
                  value: rotation.clamp(-180.0, 180.0),
                  min: -180,
                  max: 180,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceVariant,
                  onChanged: onFineRotation,
                ),
              ),
              const Text('180°',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final double iconRotation;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.iconRotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  active ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Transform.rotate(
                angle: iconRotation,
                child: Icon(
                  icon,
                  color:
                      active ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}
