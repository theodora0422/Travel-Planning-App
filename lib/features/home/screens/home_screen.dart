import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../city_selection/screens/city_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double mobileBreakpoint = 700;
  static const double webBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        return Scaffold(
          body: SafeArea(
            child: width < mobileBreakpoint
                ? const _MobileHomeLayout()
                : width < webBreakpoint
                    ? const _TabletHomeLayout()
                    : const _WebHomeLayout(),
          ),
        );
      },
    );
  }
}

class _MobileHomeLayout extends StatelessWidget {
  const _MobileHomeLayout();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Travel Planning App',
                textAlign: TextAlign.center,
                style: AppTextStyles.appBarTitle,
              ),
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                margin: const EdgeInsets.symmetric(horizontal: 90),
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
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  size: 54,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Plan your perfect\ncity adventure',
                textAlign: TextAlign.center,
                style: AppTextStyles.heroTitle,
              ),
              const SizedBox(height: 12),
              const Text(
                'Create personalized multi-day itineraries and organize every stop beautifully.',
                textAlign: TextAlign.center,
                style: AppTextStyles.heroSubtitle,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    _CompactInfoRow(
                      icon: Icons.location_city_rounded,
                      text: 'Choose any city',
                    ),
                    SizedBox(height: 12),
                    _CompactInfoRow(
                      icon: Icons.calendar_view_day_rounded,
                      text: 'Plan one or more days',
                    ),
                    SizedBox(height: 12),
                    _CompactInfoRow(
                      icon: Icons.place_rounded,
                      text: 'Customize locations and durations',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CitySelectionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create new trip'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_outline_rounded),
                label: const Text('View saved trips'),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletHomeLayout extends StatelessWidget {
  const _TabletHomeLayout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Travel Planning App',
                style: AppTextStyles.appBarTitle,
              ),
              const SizedBox(height: 28),
              Container(
                width: 120,
                height: 120,
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
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  size: 58,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Design unforgettable trips,\none day at a time.',
                textAlign: TextAlign.center,
                style: AppTextStyles.heroTitle,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create beautiful itineraries for any city, organize activities across multiple days, and personalize every stop with your own notes, durations, and locations.',
                textAlign: TextAlign.center,
                style: AppTextStyles.heroSubtitle,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
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
                child: const Column(
                  children: [
                    Text(
                      'Start planning',
                      style: AppTextStyles.sectionTitle,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Create a new trip or continue working on an existing one.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heroSubtitle,
                    ),
                    SizedBox(height: 24),
                    _CompactInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Choose any city in the world',
                    ),
                    SizedBox(height: 12),
                    _CompactInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Plan 1 or more days with ease',
                    ),
                    SizedBox(height: 12),
                    _CompactInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Generate customizable itineraries',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CitySelectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create new trip'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  label: const Text('View saved trips'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebHomeLayout extends StatelessWidget {
  const _WebHomeLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 10,
          child: _WebLeftPanel(),
        ),
        Container(
          width: 1,
          color: AppColors.border,
        ),
        const Expanded(
          flex: 10,
          child: _WebRightPanel(),
        ),
      ],
    );
  }
}

class _WebLeftPanel extends StatelessWidget {
  const _WebLeftPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Travel Planning App',
                style: AppTextStyles.appBarTitle,
              ),
              const SizedBox(height: 48),
              Container(
                width: 130,
                height: 130,
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
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  size: 64,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Design unforgettable trips,\none day at a time.',
                style: AppTextStyles.heroTitle,
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 520,
                child: Text(
                  'Create beautiful itineraries for any city, organize activities across multiple days, and personalize every stop with your own notes, durations, and locations.',
                  style: AppTextStyles.heroSubtitle,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: const [
                  _FeatureChip(
                    icon: Icons.location_city_rounded,
                    text: 'City search',
                  ),
                  _FeatureChip(
                    icon: Icons.calendar_today_rounded,
                    text: 'Multi-day planning',
                  ),
                  _FeatureChip(
                    icon: Icons.route_rounded,
                    text: 'Editable timeline',
                  ),
                  _FeatureChip(
                    icon: Icons.place_rounded,
                    text: 'Custom locations',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebRightPanel extends StatelessWidget {
  const _WebRightPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFCFD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 64,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
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
                    child: const Column(
                      children: [
                        Text(
                          'Start planning',
                          style: AppTextStyles.sectionTitle,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Create a new trip or continue working on an existing one.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heroSubtitle,
                        ),
                        SizedBox(height: 24),
                        _CompactInfoRow(
                          icon: Icons.check_circle_outline_rounded,
                          text: 'Choose any city in the world',
                        ),
                        SizedBox(height: 12),
                        _CompactInfoRow(
                          icon: Icons.check_circle_outline_rounded,
                          text: 'Plan 1 or more days with ease',
                        ),
                        SizedBox(height: 12),
                        _CompactInfoRow(
                          icon: Icons.check_circle_outline_rounded,
                          text: 'Generate customizable itineraries',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CitySelectionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create new trip'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_outline_rounded),
                      label: const Text('View saved trips'),
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

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({
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