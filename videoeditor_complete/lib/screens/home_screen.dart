import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/project_model.dart';
import '../utils/constants.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<_RecentProject> _recentProjects = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _recentProjects.isEmpty
                  ? _buildEmptyState()
                  : _buildProjectGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Project',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo + Title
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.movie_filter,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VideoEditor',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Pro Video Editing',
                style: TextStyle(
                    color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          // Settings icon
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.video_library_outlined,
                color: AppColors.textTertiary, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'No projects yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "New Project" to start editing',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),
          // Quick action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickAction(
                icon: Icons.videocam,
                label: 'Camera',
                onTap: () => _pickFromCamera(),
              ),
              const SizedBox(width: 16),
              _QuickAction(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickFromGallery(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'RECENT PROJECTS',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: _recentProjects.length,
            itemBuilder: (ctx, i) {
              final p = _recentProjects[i];
              return _ProjectCard(
                project: p,
                onTap: () => _openProject(p),
                onDelete: () => setState(() => _recentProjects.removeAt(i)),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewProjectSheet(
        onPickGallery: _pickFromGallery,
        onPickCamera: _pickFromCamera,
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (Navigator.canPop(context)) Navigator.pop(context);
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) {
      _createProjectWithVideo(video.path);
    }
  }

  Future<void> _pickFromCamera() async {
    if (Navigator.canPop(context)) Navigator.pop(context);
    final video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null && mounted) {
      _createProjectWithVideo(video.path);
    }
  }

  void _createProjectWithVideo(String videoPath) {
    final provider = context.read<EditorProvider>();
    final projectName =
        'Project ${_recentProjects.length + 1}';

    provider.createNewProject(projectName);
    provider.addVideoClip(videoPath);

    final recent = _RecentProject(
      name: projectName,
      videoPath: videoPath,
      createdAt: DateTime.now(),
    );

    setState(() => _recentProjects.insert(0, recent));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  void _openProject(_RecentProject p) {
    final provider = context.read<EditorProvider>();
    provider.createNewProject(p.name);
    provider.addVideoClip(p.videoPath);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }
}

// ── NEW PROJECT BOTTOM SHEET ───────────────────────────────────────────────────

class _NewProjectSheet extends StatelessWidget {
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  const _NewProjectSheet({
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'New Project',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          // Import options
          _ImportOption(
            icon: Icons.photo_library_outlined,
            title: 'Import from Gallery',
            subtitle: 'Pick a video from your phone',
            color: AppColors.accent,
            onTap: onPickGallery,
          ),
          const SizedBox(height: 12),
          _ImportOption(
            icon: Icons.videocam_outlined,
            title: 'Record with Camera',
            subtitle: 'Record a new video right now',
            color: AppColors.accentGreen,
            onTap: onPickCamera,
          ),
          const SizedBox(height: 12),
          _ImportOption(
            icon: Icons.folder_outlined,
            title: 'Browse Files',
            subtitle: 'Open from internal storage',
            color: AppColors.accentYellow,
            onTap: () {
              Navigator.pop(context);
              // file_picker integration can go here
            },
          ),
        ],
      ),
    );
  }
}

class _ImportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ImportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── PROJECT CARD ───────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final _RecentProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Expanded(
              child: Container(
                color: AppColors.background,
                child: const Center(
                  child: Icon(Icons.movie, color: Colors.white12, size: 40),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(project.createdAt),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined,
                color: AppColors.textSecondary),
            title: const Text('Open',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              onTap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── QUICK ACTION BUTTON ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.textTertiary.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── LOCAL MODEL ────────────────────────────────────────────────────────────────

class _RecentProject {
  final String name;
  final String videoPath;
  final DateTime createdAt;

  _RecentProject({
    required this.name,
    required this.videoPath,
    required this.createdAt,
  });
}
