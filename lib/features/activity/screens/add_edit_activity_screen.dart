import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/place_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'map_picker_screen.dart';

class AddEditActivityScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCity;
  final Map<String, dynamic>? existingActivity;
  final bool isEdit;
  final List<Map<String, dynamic>> currentDayActivities;

  const AddEditActivityScreen({
    super.key,
    required this.selectedCity,
    required this.currentDayActivities,
    this.existingActivity,
    this.isEdit = false,
  });

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final PlaceApiService _placeApiService = PlaceApiService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Timer? _debounce;
  bool _isAutocompleteLoading = false;
  bool _isDetailsLoading = false;
  bool _isMapResolving = false;
  List<Map<String, dynamic>> _suggestions = [];
  String? _selectedPlaceId;
  late String _sessionToken;

  @override
  void initState() {
    super.initState();
    _sessionToken = DateTime.now().microsecondsSinceEpoch.toString();

    if (widget.isEdit && widget.existingActivity != null) {
      final activity = widget.existingActivity!;
      _selectedPlaceId = activity['placeId']?.toString();
      _titleController.text = activity['title']?.toString() ?? '';
      _searchController.text = activity['title']?.toString() ?? '';
      _latitudeController.text = activity['latitude']?.toString() ?? '';
      _longitudeController.text = activity['longitude']?.toString() ?? '';
      _durationController.text =
          (activity['durationMinutes'] ?? 60).toString();
      _commentsController.text = activity['comments']?.toString() ?? '';
    } else {
      _durationController.text = '90';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _titleController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _durationController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isAutocompleteLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        setState(() {
          _isAutocompleteLoading = true;
        });

        final results = await _placeApiService.autocompletePlaces(
          query: value,
          cityName: widget.selectedCity['name']?.toString() ?? '',
          country: widget.selectedCity['country']?.toString() ?? '',
          sessionToken: _sessionToken,
        );

        if (!mounted) return;

        setState(() {
          _suggestions = results;
          _isAutocompleteLoading = false;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _suggestions = [];
          _isAutocompleteLoading = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['placeId']?.toString();
    if (placeId == null || placeId.isEmpty) return;

    try {
      setState(() {
        _isDetailsLoading = true;
      });

      final details = await _placeApiService.getPlaceDetails(
        placeId: placeId,
        sessionToken: _sessionToken,
      );

      if (!mounted) return;

      _selectedPlaceId = placeId;
      _searchController.text = suggestion['mainText']?.toString() ?? '';
      _titleController.text = details['title']?.toString() ?? '';
      _latitudeController.text = details['latitude']?.toString() ?? '';
      _longitudeController.text = details['longitude']?.toString() ?? '';
      _durationController.text = (details['durationMinutes'] ?? 90).toString();
      _commentsController.text = details['comments']?.toString() ?? '';

      setState(() {
        _suggestions = [];
        _isDetailsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDetailsLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load place details: $e')),
      );
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          selectedCity: widget.selectedCity,
          activities: widget.currentDayActivities,
          initialLatitude: double.tryParse(_latitudeController.text.trim()),
          initialLongitude: double.tryParse(_longitudeController.text.trim()),
        ),
      ),
    );

    if (result == null) return;

    final latitude = result['latitude'] as double;
    final longitude = result['longitude'] as double;

    _latitudeController.text = latitude.toString();
    _longitudeController.text = longitude.toString();

    try {
      setState(() {
        _isMapResolving = true;
      });

      final place = await _placeApiService.getPlaceFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      _selectedPlaceId = place['placeId']?.toString();
      _searchController.text = place['title']?.toString() ?? '';
      _titleController.text = place['title']?.toString() ?? '';
      _durationController.text = (place['durationMinutes'] ?? 90).toString();
      _commentsController.text = place['comments']?.toString() ?? '';

      setState(() {
        _isMapResolving = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isMapResolving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinates selected, but place lookup failed: $e'),
        ),
      );
    }
  }

  void _saveActivity() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide valid geographical coordinates.'),
        ),
      );
      return;
    }

    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a valid duration.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'placeId': _selectedPlaceId,
      'title': _titleController.text.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'durationMinutes': duration,
      'comments': _commentsController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final cityName = widget.selectedCity['name']?.toString() ?? '';
    final country = widget.selectedCity['country']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit activity' : 'Add activity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEdit
                          ? 'Update the activity details.'
                          : 'Search for a place in $cityName, $country or fill the fields manually.',
                      style: AppTextStyles.heroSubtitle,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search place',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _isAutocompleteLoading ||
                                _isDetailsLoading ||
                                _isMapResolving
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: _suggestions.map((item) {
                            return ListTile(
                              onTap: () => _selectSuggestion(item),
                              leading: const Icon(
                                Icons.place_rounded,
                                color: AppColors.primary,
                              ),
                              title: Text(item['mainText']?.toString() ?? ''),
                              subtitle: Text(
                                item['secondaryText']?.toString() ?? '',
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickOnMap,
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Pick location on map'),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Latitude required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid latitude';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Longitude required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid longitude';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Duration required';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid duration';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _commentsController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Comments',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveActivity,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          widget.isEdit ? 'Save changes' : 'Add activity',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}