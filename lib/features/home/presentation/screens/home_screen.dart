import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/home_story_strip.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/recent_zones_card.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/zone_preview_card.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/mock_venues.dart';

class HomeScreen extends StatelessWidget {
  final String? activeZoneName;
  final int? activeUserCount;
  final String? activeZoneImageUrl;

  const HomeScreen({
    super.key,
    this.activeZoneName,
    this.activeUserCount,
    this.activeZoneImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Say Hi',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const HomeStoryStrip(),
              const SizedBox(height: 20),
              ZonePreviewCard(
                activeZoneName: activeZoneName,
                activeUserCount: activeUserCount,
                venueImageUrl: activeZoneImageUrl,
                onTap: activeZoneName != null && activeZoneName!.isNotEmpty
                    ? () => context.push(AppRouter.zoneMainPath)
                    : null,
              ),
              const SizedBox(height: 20),
              RecentZonesCard(zones: MockVenues.all),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

