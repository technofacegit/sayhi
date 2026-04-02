import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  List<_OnboardingPageData> _pages(BuildContext context) {
    final l10n = context.l10n;
    return [
      _OnboardingPageData(
        title: l10n.onboardingPage1Title,
        subtitle: l10n.onboardingPage1Subtitle,
        icon: Icons.qr_code_rounded,
      ),
      _OnboardingPageData(
        title: l10n.onboardingPage2Title,
        subtitle: l10n.onboardingPage2Subtitle,
        icon: Icons.favorite_rounded,
      ),
      _OnboardingPageData(
        title: l10n.onboardingPage3Title,
        subtitle: l10n.onboardingPage3Subtitle,
        icon: Icons.chat_bubble_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final pages = _pages(context);
    final isLast = _pageIndex == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppRouter.loginPath),
                  child: Text(
                    l10n.onboardingSkip,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return _OnboardingPage(
                      title: page.title,
                      subtitle: page.subtitle,
                      icon: page.icon,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _DotsIndicator(
                count: pages.length,
                index: _pageIndex,
                activeColor: colorScheme.onSurface,
                inactiveColor: colorScheme.onSurface.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    if (isLast) {
                      context.go(AppRouter.loginPath);
                      return;
                    }
                    await _pageController.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Text(isLast ? l10n.onboardingStart : l10n.onboardingContinue),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 164,
              width: 164,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.secondary.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.35,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;

  const _DotsIndicator({
    required this.count,
    required this.index,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: selected ? 22 : 8,
          decoration: BoxDecoration(
            color: selected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
