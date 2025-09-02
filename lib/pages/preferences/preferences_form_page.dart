import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../models/preferences_model.dart';

class PreferencesFormPage extends StatefulWidget {
  final String userId;

  const PreferencesFormPage({super.key, required this.userId});

  @override
  State<PreferencesFormPage> createState() => _PreferencesFormPageState();
}

class _PreferencesFormPageState extends State<PreferencesFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Predefined options
  final List<String> _availableGenres = [
    'Action', 'Adventure', 'Comedy', 'Drama', 'Fantasy', 'Horror',
    'Mystery', 'Romance', 'Sci-Fi', 'Slice of Life', 'Sports', 'Supernatural'
  ];

  final List<String> _availableLanguages = [
    'English', 'Japanese', 'Korean', 'Chinese', 'Spanish', 'French', 'German'
  ];

  // Form state
  Set<String> _selectedGenres = {};
  List<String> _authorsList = [];
  double _rating = 0.0;
  Set<String> _selectedLanguages = {};
  bool _ongoing = true;
  bool _loading = false;

  // Controllers
  final TextEditingController _authorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  @override
  void dispose() {
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPreferences() async {
    setState(() => _loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('preferences')
          .doc('manga')
          .get();

      if (doc.exists) {
        final prefs = PreferencesModel.fromFirestore(doc);
        setState(() {
          _selectedGenres = prefs.genres.toSet();
          _authorsList = List.from(prefs.authors);
          _rating = prefs.rating;
          _selectedLanguages = prefs.languages.toSet();
          _ongoing = prefs.ongoing;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading preferences: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final prefs = PreferencesModel(
        genres: _selectedGenres.toList(),
        authors: _authorsList,
        rating: _rating,
        languages: _selectedLanguages.toList(),
        ongoing: _ongoing,
        userId: widget.userId,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('preferences')
          .doc('manga')
          .set(prefs.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addAuthor() {
    final author = _authorController.text.trim();
    if (author.isNotEmpty && !_authorsList.contains(author)) {
      setState(() {
        _authorsList.add(author);
        _authorController.clear();
      });
    }
  }

  void _removeAuthor(String author) {
    setState(() {
      _authorsList.remove(author);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.appBackground,
        appBar: AppBar(title: const Text('Set Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Set Preferences'),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Genres Section
              _buildSectionTitle('Preferred Genres'),
              const SizedBox(height: 8),
              _buildGenreChips(),
              
              const SizedBox(height: 24),
              
              // Authors Section
              _buildSectionTitle('Favorite Authors'),
              const SizedBox(height: 8),
              _buildAuthorInput(),
              const SizedBox(height: 8),
              _buildAuthorChips(),
              
              const SizedBox(height: 24),
              
              // Rating Section
              _buildSectionTitle('Minimum Rating'),
              const SizedBox(height: 8),
              _buildRatingSlider(),
              
              const SizedBox(height: 24),
              
              // Languages Section
              _buildSectionTitle('Preferred Languages'),
              const SizedBox(height: 8),
              _buildLanguageChips(),
              
              const SizedBox(height: 24),
              
              // Status Section
              _buildSectionTitle('Manga Status Preference'),
              const SizedBox(height: 8),
              _buildStatusToggle(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.widgetBorder, width: 1),
                    ),
                  ),
                  child: const Text(
                    'Save Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGenreChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.widgetBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableGenres.map((genre) {
          final isSelected = _selectedGenres.contains(genre);
          return FilterChip(
            label: Text(genre),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedGenres.add(genre);
                } else {
                  _selectedGenres.remove(genre);
                }
              });
            },
            backgroundColor: const Color(0xFF222222),
            selectedColor: AppTheme.iconColor.withOpacity(0.3),
            checkmarkColor: AppTheme.iconColor,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.iconColor : Colors.white70,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuthorInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.widgetBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _authorController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter author name...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.person, color: AppTheme.iconColor),
              ),
              onSubmitted: (_) => _addAuthor(),
            ),
          ),
          IconButton(
            onPressed: _addAuthor,
            icon: const Icon(Icons.add, color: AppTheme.iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorChips() {
    if (_authorsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.widgetBorder),
        ),
        child: const Center(
          child: Text(
            'No authors added yet',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.widgetBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _authorsList.map((author) {
          return Chip(
            label: Text(author),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => _removeAuthor(author),
            backgroundColor: const Color(0xFF222222),
            labelStyle: const TextStyle(color: Colors.white),
            deleteIconColor: Colors.white70,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.widgetBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minimum Rating:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                _rating == 0 ? 'Any' : '${_rating.toStringAsFixed(1)}+',
                style: const TextStyle(
                  color: AppTheme.iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _rating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppTheme.iconColor,
            inactiveColor: Colors.white24,
            onChanged: (value) {
              setState(() => _rating = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.widgetBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableLanguages.map((language) {
          final isSelected = _selectedLanguages.contains(language);
          return FilterChip(
            label: Text(language),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLanguages.add(language);
                } else {
                  _selectedLanguages.remove(language);
                }
              });
            },
            backgroundColor: const Color(0xFF222222),
            selectedColor: AppTheme.iconColor.withOpacity(0.3),
            checkmarkColor: AppTheme.iconColor,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.iconColor : Colors.white70,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.widgetBorder),
      ),
      child: SwitchListTile(
        title: const Text(
          'Prefer Ongoing Manga',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _ongoing 
              ? 'Show ongoing manga first' 
              : 'Show completed manga first',
          style: const TextStyle(color: Colors.white54),
        ),
        value: _ongoing,
        activeColor: AppTheme.iconColor,
        onChanged: (value) {
          setState(() => _ongoing = value);
        },
      ),
    );
  }
}
