import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

const Color _stravaOrange = Color(0xFFFC4C02);

/// Strava-style edit profile screen using Supabase (name + profile picture)
class StravaEditProfileScreen extends HookConsumerWidget {
  const StravaEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: _stravaOrange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: supabaseUser == null
          ? const Center(child: Text('Not signed in'))
          : _EditProfileLoader(
              userId: supabaseUser.id,
              emailFallback: supabaseUser.email ?? '',
              formKey: formKey,
            ),
    );
  }
}

/// Loads profile in background; shows form immediately so user is never stuck on loading.
class _EditProfileLoader extends StatefulWidget {
  final String userId;
  final String emailFallback;
  final GlobalKey<FormState> formKey;

  const _EditProfileLoader({
    required this.userId,
    required this.emailFallback,
    required this.formKey,
  });

  @override
  State<_EditProfileLoader> createState() => _EditProfileLoaderState();
}

class _EditProfileLoaderState extends State<_EditProfileLoader> {
  String? _fullName;
  String? _profilePictureUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService().getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _fullName = profile?['full_name'] as String? ?? widget.emailFallback;
          _profilePictureUrl = profile?['profile_picture_url'] as String?;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fullName = widget.emailFallback;
          _loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditProfileForm(
      formKey: widget.formKey,
      initialFullName: _fullName ?? widget.emailFallback,
      initialProfilePictureUrl: _profilePictureUrl,
      userId: widget.userId,
      isLoading: !_loaded,
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String initialFullName;
  final String? initialProfilePictureUrl;
  final String userId;

  const _EditProfileForm({
    required this.formKey,
    required this.initialFullName,
    this.initialProfilePictureUrl,
    required this.userId,
    this.isLoading = false,
  });

  final bool isLoading;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  String? _profilePictureUrl;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFullName);
    _profilePictureUrl = widget.initialProfilePictureUrl;
  }

  @override
  void didUpdateWidget(covariant _EditProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && widget.initialFullName.isNotEmpty) {
      _nameController.text = widget.initialFullName;
    }
    if (widget.initialProfilePictureUrl != oldWidget.initialProfilePictureUrl) {
      _profilePictureUrl = widget.initialProfilePictureUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ImageProvider<Object>? _buildProfileImage() {
    if (_pickedImageBytes != null) return MemoryImage(_pickedImageBytes!);
    final url = _profilePictureUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? profilePictureUrl = _profilePictureUrl;
      if (_pickedImageBytes != null) {
        final url = await SupabaseService().uploadProfilePicture(
          userId: widget.userId,
          imageBytes: _pickedImageBytes!,
        );
        profilePictureUrl = url ?? profilePictureUrl;
      }
      await SupabaseService().updateUserProfile(
        userId: widget.userId,
        fullName: _nameController.text.trim(),
        profilePictureUrl: profilePictureUrl,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _buildProfileImage(),
                  child: _pickedImageBytes == null &&
                          (_profilePictureUrl ?? '').isEmpty
                      ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600])
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Change profile picture'),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your name';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _stravaOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    ),
        if (widget.isLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.7),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
