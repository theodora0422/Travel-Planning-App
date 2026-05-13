import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/place_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final PlaceApiService _placeApiService = PlaceApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final placeId = widget.activity['placeId']?.toString();

    if (placeId == null || placeId.isEmpty) {
      setState(() {
        _isLoading = false;
        _details = {
          'title': widget.activity['title'],
          'comments': widget.activity['comments'],
          'latitude': widget.activity['latitude'],
          'longitude': widget.activity['longitude'],
          'address': null,
          'rating': null,
          'phoneNumber': null,
          'websiteUri': null,
          'googleMapsUri': null,
        };
      });
      return;
    }

    try {
      final details = await _placeApiService.getPlaceDetails(placeId: placeId);

      if (!mounted) return;

      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openMaps() async {
    final googleMapsUri = _details?['googleMapsUri']?.toString();
    final title = (_details?['title'] ?? widget.activity['title']).toString();
    final lat = _details?['latitude'] ?? widget.activity['latitude'];
    final lng = _details?['longitude'] ?? widget.activity['longitude'];

    Uri uri;

    if (googleMapsUri != null && googleMapsUri.isNotEmpty) {
      uri = Uri.parse(googleMapsUri);
    } else if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(title)}',
      );
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _searchOnGoogle() async {
    final title = (_details?['title'] ?? widget.activity['title']).toString();
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(title)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final title = (_details?['title'] ?? widget.activity['title'] ?? '').toString();
    final comments = (_details?['comments'] ?? widget.activity['comments'] ?? '').toString();
    final rating = _details?['rating'];
    final address = _details?['address']?.toString();
    final phone = _details?['phoneNumber']?.toString();
    final website = _details?['websiteUri']?.toString();
    final lat = _details?['latitude'] ?? widget.activity['latitude'];
    final lng = _details?['longitude'] ?? widget.activity['longitude'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load details.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.heroTitle.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 12),
                            if (rating != null)
                              Text(
                                'Rating: $rating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            const SizedBox(height: 18),
                            _DetailBlock(
                              label: 'Description',
                              value: comments.isEmpty ? 'No extra details.' : comments,
                            ),
                            _DetailBlock(
                              label: 'Address',
                              value: address ?? 'Unknown address',
                            ),
                            _DetailBlock(
                              label: 'Phone',
                              value: phone ?? 'Not available',
                            ),
                            _DetailBlock(
                              label: 'Coordinates',
                              value: (lat != null && lng != null)
                                  ? '$lat, $lng'
                                  : 'Not available',
                            ),
                            _DetailBlock(
                              label: 'Website',
                              value: website ?? 'Not available',
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _openMaps,
                                  icon: const Icon(Icons.map_rounded),
                                  label: const Text('Open in Google Maps'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _searchOnGoogle,
                                  icon: const Icon(Icons.search_rounded),
                                  label: const Text('Search on Google'),
                                ),
                              ],
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

class _DetailBlock extends StatelessWidget {
  final String label;
  final String value;

  const _DetailBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}