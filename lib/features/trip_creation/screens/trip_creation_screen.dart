import 'package:flutter/material.dart';
import '../../../core/services/itinerary_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../itinerary/screens/itinerary_screen.dart';

class TripCreationScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCity;

  const TripCreationScreen({
    super.key,
    required this.selectedCity,
  });

  @override
  State<TripCreationScreen> createState() => _TripCreationScreenState();
}

class _TripCreationScreenState extends State<TripCreationScreen> {
  final ItineraryApiService _itineraryApiService = ItineraryApiService();

  int _days = 2;
  String _tripStyle = 'Balanced';
  bool _isGenerating = false;

  final List<String> _styles = ['Relaxed', 'Balanced', 'Packed'];

  Future<void> _continueToItinerary() async {
    try {
      setState(() {
        _isGenerating = true;
      });

      final itinerary = await _itineraryApiService.generateItinerary(
        selectedCity: widget.selectedCity,
        numberOfDays: _days,
        tripStyle: _tripStyle,
      );

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItineraryScreen(
            selectedCity: itinerary['city'] as Map<String, dynamic>,
            numberOfDays: itinerary['numberOfDays'] as int,
            tripStyle: itinerary['tripStyle'] as String,
            days: (itinerary['days'] as List)
                .map((day) => Map<String, dynamic>.from(day as Map))
                .toList(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate itinerary: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityName = widget.selectedCity['name'] ?? '';
    final country = widget.selectedCity['country'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create trip'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip details',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You selected $cityName, $country. Set the basic preferences for your itinerary.',
                    style: AppTextStyles.heroSubtitle,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceStrong,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.location_city_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cityName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                country,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Number of days',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _days > 1
                            ? () {
                                setState(() {
                                  _days--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_days day${_days == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _days++;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Trip style',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _styles.map((style) {
                      final isSelected = style == _tripStyle;

                      return ChoiceChip(
                        label: Text(style),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _tripStyle = style;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _continueToItinerary,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isGenerating
                            ? 'Generating itinerary...'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}