import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../activity/screens/activity_details_screen.dart';
import '../../activity/screens/add_edit_activity_screen.dart';
import '../../activity/screens/map_picker_screen.dart';

class ItineraryScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCity;
  final int numberOfDays;
  final String tripStyle;
  final List<Map<String, dynamic>> days;

  const ItineraryScreen({
    super.key,
    required this.selectedCity,
    required this.numberOfDays,
    required this.tripStyle,
    required this.days,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> _daysData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.numberOfDays, vsync: this);
    _daysData = widget.days
        .map((day) => {
              'dayNumber': day['dayNumber'],
              'activities': List<Map<String, dynamic>>.from(
                (day['activities'] as List).map(
                  (activity) => Map<String, dynamic>.from(activity as Map),
                ),
              ),
            })
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _activitiesForDay(int dayIndex) {
    return List<Map<String, dynamic>>.from(
      _daysData[dayIndex]['activities'] as List,
    );
  }

  Future<void> _addActivity() async {
    final currentDayIndex = _tabController.index;
    final currentDayActivities = _activitiesForDay(currentDayIndex);

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AddEditActivityScreen(
          selectedCity: widget.selectedCity,
          currentDayActivities: currentDayActivities,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final day = _activitiesForDay(currentDayIndex);
      day.add(result);
      _daysData[currentDayIndex]['activities'] = day;
    });
  }

  Future<void> _editActivity(int dayIndex, int activityIndex) async {
    final activity = _activitiesForDay(dayIndex)[activityIndex];
    final currentDayActivities = _activitiesForDay(dayIndex);

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AddEditActivityScreen(
          selectedCity: widget.selectedCity,
          currentDayActivities: currentDayActivities,
          existingActivity: activity,
          isEdit: true,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final day = _activitiesForDay(dayIndex);
      day[activityIndex] = result;
      _daysData[dayIndex]['activities'] = day;
    });
  }

  Future<void> _openDetails(Map<String, dynamic> activity) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailsScreen(activity: activity),
      ),
    );
  }

  Future<void> _openDayMap() async {
    final currentDayIndex = _tabController.index;
    final currentDayActivities = _activitiesForDay(currentDayIndex);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          selectedCity: widget.selectedCity,
          activities: currentDayActivities,
        ),
      ),
    );
  }

  void _moveUp(int dayIndex, int activityIndex) {
    if (activityIndex == 0) return;

    setState(() {
      final day = _activitiesForDay(dayIndex);
      final temp = day[activityIndex];
      day[activityIndex] = day[activityIndex - 1];
      day[activityIndex - 1] = temp;
      _daysData[dayIndex]['activities'] = day;
    });
  }

  void _moveDown(int dayIndex, int activityIndex) {
    final day = _activitiesForDay(dayIndex);
    if (activityIndex == day.length - 1) return;

    setState(() {
      final temp = day[activityIndex];
      day[activityIndex] = day[activityIndex + 1];
      day[activityIndex + 1] = temp;
      _daysData[dayIndex]['activities'] = day;
    });
  }

  void _deleteActivity(int dayIndex, int activityIndex) {
    setState(() {
      final day = _activitiesForDay(dayIndex);
      day.removeAt(activityIndex);
      _daysData[dayIndex]['activities'] = day;
    });
  }

  int _totalDurationForDay(int dayIndex) {
    final activities = _activitiesForDay(dayIndex);
    return activities.fold<int>(
      0,
      (sum, item) => sum + ((item['durationMinutes'] as int?) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityName = widget.selectedCity['name'] ?? '';
    final country = widget.selectedCity['country'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$cityName itinerary'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: List.generate(
            widget.numberOfDays,
            (index) => Tab(text: 'Day ${index + 1}'),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openDayMap,
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            onPressed: _addActivity,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add activity'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
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
                        '$country • ${widget.tripStyle} trip',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(widget.numberOfDays, (dayIndex) {
                final activities = _activitiesForDay(dayIndex);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Total planned duration: ${_totalDurationForDay(dayIndex)} min',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: activities.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_busy_outlined,
                                      size: 42,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No activities left for this day',
                                      style: AppTextStyles.sectionTitle,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: activities.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, activityIndex) {
                                  final activity = activities[activityIndex];

                                  return _ItineraryActivityCard(
                                    index: activityIndex,
                                    title: activity['title'] as String? ?? '',
                                    duration:
                                        activity['durationMinutes'] as int? ?? 0,
                                    notes:
                                        activity['comments'] as String? ?? '',
                                    onTap: () =>
                                        _editActivity(dayIndex, activityIndex),
                                    onDetails: () => _openDetails(activity),
                                    onMoveUp: () =>
                                        _moveUp(dayIndex, activityIndex),
                                    onMoveDown: () =>
                                        _moveDown(dayIndex, activityIndex),
                                    onDelete: () =>
                                        _deleteActivity(dayIndex, activityIndex),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryActivityCard extends StatelessWidget {
  final int index;
  final String title;
  final int duration;
  final String notes;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  const _ItineraryActivityCard({
    required this.index,
    required this.title,
    required this.duration,
    required this.notes,
    required this.onTap,
    required this.onDetails,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$duration min',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    onPressed: onMoveUp,
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    onPressed: onMoveDown,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: Colors.redAccent,
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