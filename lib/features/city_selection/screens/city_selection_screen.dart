import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/city_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../trip_creation/screens/trip_creation_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  static const double mobileBreakpoint = 700;
  static const double webBreakpoint = 1100;

  final TextEditingController _searchController = TextEditingController();
  final CityApiService _cityApiService = CityApiService();

  final List<Map<String, String>> _popularCities = [
    {
      'name': 'Paris',
      'country': 'France',
      'tag': 'Romantic city escapes',
    },
    {
      'name': 'Rome',
      'country': 'Italy',
      'tag': 'History and iconic landmarks',
    },
    {
      'name': 'Barcelona',
      'country': 'Spain',
      'tag': 'Art, beaches and nightlife',
    },
    {
      'name': 'Amsterdam',
      'country': 'Netherlands',
      'tag': 'Canals and culture',
    },
    {
      'name': 'Vienna',
      'country': 'Austria',
      'tag': 'Elegant architecture and museums',
    },
    {
      'name': 'Prague',
      'country': 'Czech Republic',
      'tag': 'Old town charm',
    },
  ];

  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestions = [];
  String? _errorText;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _errorText = null;
    });

    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _loadSuggestions(value);
    });
  }

  Future<void> _loadSuggestions(String value) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final results = await _cityApiService.autocompleteCities(value);

      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _suggestions = [];
        _errorText = 'Could not load city suggestions.';
      });
    }
  }

  void _goToTripCreation(Map<String, dynamic> city) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripCreationScreen(selectedCity: city),
      ),
    );
  }

  Future<void> _submitSearch() async {
    final value = _searchController.text.trim();

    if (value.isEmpty) {
      setState(() {
        _errorText = 'Please enter a city name.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });

      final validCity = await _cityApiService.validateCity(value);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (validCity == null) {
        setState(() {
          _errorText = 'This city does not exist or could not be found.';
        });
        return;
      }

      _goToTripCreation(validCity);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorText = 'Could not validate the city. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < mobileBreakpoint) {
          return _MobileCitySelectionLayout(
            searchController: _searchController,
            popularCities: _popularCities,
            suggestions: _suggestions,
            isLoading: _isLoading,
            errorText: _errorText,
            onQueryChanged: _onQueryChanged,
            onSubmit: _submitSearch,
            onCitySelected: _goToTripCreation,
          );
        }

        if (width < webBreakpoint) {
          return _TabletCitySelectionLayout(
            searchController: _searchController,
            popularCities: _popularCities,
            suggestions: _suggestions,
            isLoading: _isLoading,
            errorText: _errorText,
            onQueryChanged: _onQueryChanged,
            onSubmit: _submitSearch,
            onCitySelected: _goToTripCreation,
          );
        }

        return _WebCitySelectionLayout(
          searchController: _searchController,
          popularCities: _popularCities,
          suggestions: _suggestions,
          isLoading: _isLoading,
          errorText: _errorText,
          onQueryChanged: _onQueryChanged,
          onSubmit: _submitSearch,
          onCitySelected: _goToTripCreation,
        );
      },
    );
  }
}

class _MobileCitySelectionLayout extends StatelessWidget {
  final TextEditingController searchController;
  final List<Map<String, String>> popularCities;
  final List<Map<String, dynamic>> suggestions;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmit;
  final ValueChanged<Map<String, dynamic>> onCitySelected;

  const _MobileCitySelectionLayout({
    required this.searchController,
    required this.popularCities,
    required this.suggestions,
    required this.isLoading,
    required this.errorText,
    required this.onQueryChanged,
    required this.onSubmit,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSuggestions =
        searchController.text.trim().isNotEmpty && suggestions.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose your city'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CitySelectionHeader(
              title: 'Where do you want to go?',
              subtitle:
                  'Search for a city and start building your personalized itinerary.',
            ),
            const SizedBox(height: 18),
            _CitySearchField(
              controller: searchController,
              onChanged: onQueryChanged,
              onSubmitted: (_) => onSubmit(),
              isLoading: isLoading,
              errorText: errorText,
            ),
            const SizedBox(height: 18),
            if (hasSuggestions) ...[
              const Text(
                'Suggestions',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              _SuggestionList(
                suggestions: suggestions,
                onCitySelected: onCitySelected,
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Popular cities',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 14),
            _CityGridStrings(
              cities: popularCities,
              crossAxisCount: 1,
              childAspectRatio: 1.75,
              onCitySelected: (city){
                onCitySelected(city);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletCitySelectionLayout extends StatelessWidget {
  final TextEditingController searchController;
  final List<Map<String, String>> popularCities;
  final List<Map<String, dynamic>> suggestions;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmit;
  final ValueChanged<Map<String, dynamic>> onCitySelected;

  const _TabletCitySelectionLayout({
    required this.searchController,
    required this.popularCities,
    required this.suggestions,
    required this.isLoading,
    required this.errorText,
    required this.onQueryChanged,
    required this.onSubmit,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSuggestions =
        searchController.text.trim().isNotEmpty && suggestions.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose your city'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                const _CitySelectionHeader(
                  title: 'Find the perfect destination',
                  subtitle:
                      'Browse popular cities and start planning your trip in a visually organized way.',
                  centered: true,
                ),
                const SizedBox(height: 22),
                _CitySearchField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  onSubmitted: (_) => onSubmit(),
                  isLoading: isLoading,
                  errorText: errorText,
                ),
                const SizedBox(height: 22),
                if (hasSuggestions) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Suggestions',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SuggestionList(
                    suggestions: suggestions,
                    onCitySelected: onCitySelected,
                  ),
                  const SizedBox(height: 24),
                ],
                _CityGridStrings(
                  cities: popularCities,
                  crossAxisCount: 1,
                  childAspectRatio: 1.75,
                  onCitySelected:(city){
                    onCitySelected(city);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebCitySelectionLayout extends StatelessWidget {
  final TextEditingController searchController;
  final List<Map<String, String>> popularCities;
  final List<Map<String, dynamic>> suggestions;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmit;
  final ValueChanged<Map<String, dynamic>> onCitySelected;

  const _WebCitySelectionLayout({
    required this.searchController,
    required this.popularCities,
    required this.suggestions,
    required this.isLoading,
    required this.errorText,
    required this.onQueryChanged,
    required this.onSubmit,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSuggestions =
        searchController.text.trim().isNotEmpty && suggestions.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: Container(
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Travel Planning App',
                        style: AppTextStyles.appBarTitle,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD3E2),
                              Color(0xFFF8BBD0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          size: 54,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Choose a destination\nthat inspires you.',
                        style: AppTextStyles.heroTitle,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 520,
                        child: Text(
                          'Search through cities, explore curated options, and begin your itinerary with a polished travel-planning experience.',
                          style: AppTextStyles.heroSubtitle,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: const [
                          _InfoPill(
                            icon: Icons.search_rounded,
                            text: 'Smart search',
                          ),
                          _InfoPill(
                            icon: Icons.style_rounded,
                            text: 'Beautiful UI',
                          ),
                          _InfoPill(
                            icon: Icons.calendar_month_rounded,
                            text: 'Trip planning',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              color: AppColors.border,
            ),
            Expanded(
              flex: 11,
              child: Container(
                color: const Color(0xFFFFFCFD),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search city',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Select the destination that will become the base of your itinerary.',
                            style: AppTextStyles.heroSubtitle,
                          ),
                          const SizedBox(height: 22),
                          _CitySearchField(
                            controller: searchController,
                            onChanged: onQueryChanged,
                            onSubmitted: (_) => onSubmit(),
                            isLoading: isLoading,
                            errorText: errorText,
                          ),
                          const SizedBox(height: 22),
                          if (hasSuggestions) ...[
                            const Text(
                              'Suggestions',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 14),
                            _SuggestionList(
                              suggestions: suggestions,
                              onCitySelected: onCitySelected,
                            ),
                            const SizedBox(height: 24),
                          ],
                          const Text(
                            'Popular cities',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 14),
                          _CityGridStrings(
                            cities: popularCities,
                            crossAxisCount: 2,
                            onCitySelected: (city){
                              onCitySelected(city);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitySelectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool centered;

  const _CitySelectionHeader({
    required this.title,
    required this.subtitle,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppTextStyles.heroTitle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppTextStyles.heroSubtitle,
        ),
      ],
    );
  }
}

class _CitySearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool isLoading;
  final String? errorText;

  const _CitySearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.isLoading,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by city or country',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: controller.text.trim().isEmpty
                        ? null
                        : () => onSubmitted(controller.text),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                    ),
                  ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<Map<String, dynamic>> onCitySelected;

  const _SuggestionList({
    required this.suggestions,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: suggestions.map((city) {
        final name = city['name'] ?? '';
        final country = city['country'] ?? '';
        final region = city['region'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCitySelected(city),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(14),
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
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            region.toString().isEmpty
                                ? country
                                : '$region, $country',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CityGridStrings extends StatelessWidget {
  final List<Map<String, String>> cities;
  final int crossAxisCount;
  final double childAspectRatio;
  final ValueChanged<Map<String, String>> onCitySelected;

  const _CityGridStrings({
    required this.cities,
    required this.crossAxisCount,
    required this.onCitySelected,
    this.childAspectRatio = 1.42,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cities.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final city = cities[index];
        return _CityCardString(
          city: city,
          onTap: () {
            onCitySelected({
              'name': city['name']??'',
              'country': city['country']??'',
              'tag': city['tag']??'',
            });
          },
        );
      },
    );
  }
}

class _CityCardString extends StatelessWidget {
  final Map<String, String> city;
  final VoidCallback onTap;

  const _CityCardString({
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceStrong,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  city['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  city['country'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  city['tag'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}