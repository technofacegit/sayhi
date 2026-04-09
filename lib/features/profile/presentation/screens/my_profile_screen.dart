import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_dating_app/core/profile_location_sync.dart';
import 'package:qr_dating_app/features/profile/data/my_profile_repository.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final MyProfileRepository _repo = MyProfileRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _interestInputController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Object? _error;
  MyProfileData? _profile;
  final List<String> _interests = <String>[];
  final List<String?> _photoSlots = List<String?>.filled(5, null);
  bool _photoBusy = false;
  bool _locBusy = false;
  int? _draggingSlotIndex;

  @override
  void initState() {
    super.initState();
    // ignore: unawaited_futures
    _initialLoad();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _interestInputController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await _load();
    if (!mounted) return;
    if ((_profile?.location ?? '').trim().isEmpty) {
      await _syncLocationFromDevice(silent: true);
    }
  }

  Future<void> _syncLocationFromDevice({bool silent = false}) async {
    if (_locBusy) return;
    setState(() => _locBusy = true);
    try {
      final ok = await ProfileLocationSync().syncFromDevice();
      if (!mounted) return;
      if (ok) {
        final country = await _repo.fetchMyCountry();
        if (!mounted) return;
        final prev = _profile;
        if (prev != null) {
          setState(() => _profile = prev.copyWithLocation(country));
        }
        if (!silent) _snackBar('Konum güncellendi');
      } else if (!silent) {
        _snackBar(
          'Konum alınamadı. Konum servisini ve uygulama konum iznini kontrol et.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) _snackBar('Konum alınamadı: $e');
    } finally {
      if (mounted) setState(() => _locBusy = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.fetchMyProfile();
      if (!mounted) return;
      _profile = p;
      _nameController.text = p.name;
      _bioController.text = p.bio;
      _ageController.text = p.age?.toString() ?? '';
      _promptController.text = p.perfectDatePrompt;
      _interests
        ..clear()
        ..addAll(p.interests);
      for (var i = 0; i < _photoSlots.length; i++) {
        _photoSlots[i] = i < p.photoUrls.length ? p.photoUrls[i] : null;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  int _profileStrengthPercent() {
    var score = 0;
    final has3Photos = _currentPhotos().length >= 3;
    if (has3Photos) score++;
    if (_nameController.text.trim().isNotEmpty) score++;
    if (_bioController.text.trim().isNotEmpty) score++;
    if (int.tryParse(_ageController.text.trim()) != null) score++;
    if ((_profile?.location ?? '').trim().isNotEmpty) score++;
    if (_interests.isNotEmpty) score++;
    if (_promptController.text.trim().isNotEmpty) score++;
    return ((score / 7) * 100).round();
  }

  List<String> _currentPhotos() => _photoSlots
      .whereType<String>()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  void _snackBar(String message) {
    debugPrint('[MyProfile] $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<ImageSource?> _pickPhotoSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Fotoğraf çek'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galeriden seç'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onPhotoSlotTap(int index) async {
    if (_photoBusy) return;
    final hasPhoto = (_photoSlots[index] ?? '').trim().isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  hasPhoto ? Icons.swap_horiz_rounded : Icons.add_a_photo_rounded,
                ),
                title: Text(hasPhoto ? 'Fotoğrafı değiştir' : 'Fotoğraf ekle'),
                onTap: () => Navigator.of(ctx).pop('pick'),
              ),
              if (hasPhoto && index != 0)
                ListTile(
                  leading: const Icon(Icons.star_rounded),
                  title: const Text('Main fotoğraf yap'),
                  onTap: () => Navigator.of(ctx).pop('make_main'),
                ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Fotoğrafı sil'),
                  onTap: () => Navigator.of(ctx).pop('delete'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (action == null) return;
    if (action == 'make_main') {
      await _makeMainPhoto(index);
      return;
    }
    if (action == 'delete') {
      await _deletePhotoAt(index);
      return;
    }
    final source = await _pickPhotoSource();
    if (source == null) return;
    await _pickAndUploadAt(index, source);
  }

  Future<void> _makeMainPhoto(int index) async {
    if (_photoBusy) return;
    final url = (_photoSlots[index] ?? '').trim();
    if (url.isEmpty || index == 0) return;
    setState(() => _photoBusy = true);
    try {
      final main = _photoSlots[0];
      _photoSlots[0] = url;
      _photoSlots[index] = main;
      await _repo.updateMyPhotoUrls(_currentPhotos());
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _snackBar('Main fotoğraf ayarlanamadı: $e');
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _swapPhotoSlots(int from, int to) async {
    if (_photoBusy || from == to) return;
    setState(() => _photoBusy = true);
    try {
      final tmp = _photoSlots[from];
      _photoSlots[from] = _photoSlots[to];
      _photoSlots[to] = tmp;
      await _repo.updateMyPhotoUrls(_currentPhotos());
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _snackBar('Sıra değiştirilemedi: $e');
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<String?> _cropToSquare(String imagePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı kırp',
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Fotoğrafı kırp',
          aspectRatioLockEnabled: true,
          rotateButtonsHidden: false,
        ),
      ],
    );
    return cropped?.path;
  }

  Future<void> _deletePhotoAt(int index) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      _photoSlots[index] = null;
      // Compact photos so avatar stays first non-empty and no holes in DB.
      final compact = _currentPhotos();
      for (var i = 0; i < _photoSlots.length; i++) {
        _photoSlots[i] = i < compact.length ? compact[i] : null;
      }
      await _repo.updateMyPhotoUrls(_currentPhotos());
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _snackBar('Fotoğraf silinemedi: $e');
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _pickAndUploadAt(int index, ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final croppedPath = await _cropToSquare(picked.path);
      if (croppedPath == null) return;
      final url = await _repo.uploadProfilePhoto(filePath: croppedPath);
      _photoSlots[index] = url;
      await _repo.updateMyPhotoUrls(_currentPhotos());
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _snackBar('Fotoğraf yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final ageRaw = _ageController.text.trim();
    final age = ageRaw.isEmpty ? null : int.tryParse(ageRaw);
    if (ageRaw.isNotEmpty && age == null) {
      _snackBar('Yaş sayısal olmalı');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _snackBar('İsim gerekli');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.updateMyProfile(
        name: _nameController.text,
        bio: _bioController.text,
        age: age,
        interests: List<String>.from(_interests),
        perfectDatePrompt: _promptController.text,
      );
      if (!mounted) return;
      _snackBar('Profil güncellendi');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snackBar('Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addInterestFromInput() {
    final t = _interestInputController.text.trim();
    if (t.isEmpty) return;
    if (_interests.contains(t)) {
      _interestInputController.clear();
      return;
    }
    setState(() {
      _interests.add(t);
      _interestInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final p = _profile;
    final strength = _profileStrengthPercent();

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null || p == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Profil yüklenemedi'),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StrengthCard(percent: strength),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Fotoğraflar',
                      subtitle: '${_currentPhotos().length}/5',
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 5,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemBuilder: (context, i) {
                              final u = _photoSlots[i];
                              final has = (u ?? '').trim().isNotEmpty;
                              final slot = _PhotoSlotTile(
                                url: u,
                                isMain: i == 0,
                                onSurfaceVariant: colors.onSurfaceVariant,
                                dragging: _draggingSlotIndex == i,
                              );
                              return DragTarget<int>(
                                onWillAcceptWithDetails: (d) {
                                  return !_photoBusy && d.data != i;
                                },
                                onAcceptWithDetails: (d) {
                                  _swapPhotoSlots(d.data, i);
                                },
                                builder: (context, _, __) {
                                  return LongPressDraggable<int>(
                                    data: i,
                                    dragAnchorStrategy: pointerDragAnchorStrategy,
                                    onDragStarted: () =>
                                        setState(() => _draggingSlotIndex = i),
                                    onDraggableCanceled: (_, __) =>
                                        setState(() => _draggingSlotIndex = null),
                                    onDragEnd: (_) =>
                                        setState(() => _draggingSlotIndex = null),
                                    feedback: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: _PhotoSlotTile(
                                          url: u,
                                          isMain: i == 0,
                                          onSurfaceVariant: colors.onSurfaceVariant,
                                          dragging: false,
                                        ),
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: _photoBusy
                                          ? null
                                          : () => _onPhotoSlotTap(i),
                                      borderRadius: BorderRadius.circular(10),
                                      child: slot,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (_photoBusy) ...[
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Fotoğraf güncelleniyor...'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'İsim',
                      child: TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Görünen adın',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Bio / About me',
                      child: TextField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Kendini kısaca anlat',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Yaş, Lokasyon',
                      subtitle:
                          'Ülke, cihaz konumundan alınır (keşif filtreleriyle uyumlu).',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Yaş',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  (p.location.trim().isEmpty)
                                      ? 'Konum henüz alınmadı'
                                      : p.location.trim(),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonalIcon(
                                onPressed: (_locBusy || _loading)
                                    ? null
                                    : () => _syncLocationFromDevice(),
                                icon: _locBusy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.my_location_rounded),
                                label: Text(_locBusy ? '...' : 'Konumu güncelle'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'İlgi alanları (tags)',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _interestInputController,
                                  onSubmitted: (_) => _addInterestFromInput(),
                                  decoration: const InputDecoration(
                                    hintText: 'Tag ekle (örn: kahve)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _addInterestFromInput,
                                child: const Text('Ekle'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in _interests)
                                InputChip(
                                  label: Text(t),
                                  onDeleted: () =>
                                      setState(() => _interests.remove(t)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Prompt',
                      subtitle: 'Perfect date?',
                      child: TextField(
                        controller: _promptController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Perfect date nedir?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _MyProfilePreviewScreen(
                              name: _nameController.text.trim(),
                              bio: _bioController.text.trim(),
                              age: int.tryParse(_ageController.text.trim()),
                              location: p.location.trim(),
                              photos: _currentPhotos(),
                              interests: List<String>.from(_interests),
                              prompt: _promptController.text.trim(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Profil önizleme (başkası nasıl görüyor)'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Kaydet'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile strength: $percent%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 6),
            Text(
              'Profil tamamlandıkça match şansın artar.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSlotTile extends StatelessWidget {
  const _PhotoSlotTile({
    required this.url,
    required this.isMain,
    required this.onSurfaceVariant,
    required this.dragging,
  });

  final String? url;
  final bool isMain;
  final Color onSurfaceVariant;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final has = (url ?? '').trim().isNotEmpty;
    return Opacity(
      opacity: dragging ? 0.45 : 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: has
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Colors.black12),
                    )
                  : ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.add_rounded, color: onSurfaceVariant),
                    ),
            ),
          ),
          if (isMain)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _MyProfilePreviewScreen extends StatelessWidget {
  const _MyProfilePreviewScreen({
    required this.name,
    required this.bio,
    required this.age,
    required this.location,
    required this.photos,
    required this.interests,
    required this.prompt,
  });

  final String name;
  final String bio;
  final int? age;
  final String location;
  final List<String> photos;
  final List<String> interests;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil önizleme')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          SizedBox(
            height: 360,
            child: photos.isEmpty
                ? const ColoredBox(color: Colors.black12)
                : PageView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Colors.black12),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            age != null ? '$name, $age' : name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (location.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.public_rounded, size: 16),
                const SizedBox(width: 6),
                Text(location),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text('About me', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(bio.isEmpty ? '—' : bio),
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final t in interests) Chip(label: Text(t))],
            ),
          ],
          if (prompt.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Perfect date?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(prompt),
          ],
        ],
      ),
    );
  }
}
