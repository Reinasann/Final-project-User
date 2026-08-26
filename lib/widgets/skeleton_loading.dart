import 'package:flutter/material.dart';

enum AppSkeletonLayout { cards, list, report, profile, form }

class AppSkeletonLoading extends StatefulWidget {
  final AppSkeletonLayout layout;

  const AppSkeletonLoading({
    super.key,
    this.layout = AppSkeletonLayout.list,
  });

  @override
  State<AppSkeletonLoading> createState() => _AppSkeletonLoadingState();
}

class _AppSkeletonLoadingState extends State<AppSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block(
    Color color, {
    double? width,
    required double height,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _lineGroup(Color color, {double titleWidth = 150}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _block(color, width: titleWidth, height: 16, radius: 6),
          const SizedBox(height: 10),
          _block(color, width: 220, height: 12, radius: 6),
          const SizedBox(height: 8),
          _block(color, width: 110, height: 12, radius: 6),
        ],
      ),
    );
  }

  Widget _cardItem(Color color, {bool compact = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _block(
            color,
            width: compact ? 44 : 60,
            height: compact ? 44 : 60,
            radius: compact ? 22 : 12,
          ),
          const SizedBox(width: 16),
          _lineGroup(color, titleWidth: compact ? 125 : 165),
        ],
      ),
    );
  }

  Widget _cards(Color color) {
    return ListView(
      key: const ValueKey('skeleton-cards'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (_) => _cardItem(color)),
    );
  }

  Widget _list(Color color) {
    return ListView(
      key: const ValueKey('skeleton-list'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _block(color, height: 54),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _block(color, height: 50)),
            const SizedBox(width: 10),
            _block(color, width: 50, height: 50),
          ],
        ),
        const SizedBox(height: 18),
        ...List.generate(5, (_) => _cardItem(color, compact: true)),
      ],
    );
  }

  Widget _report(Color color) {
    return ListView(
      key: const ValueKey('skeleton-report'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _block(color, width: 190, height: 20, radius: 7),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _block(color, height: 52)),
                  const SizedBox(width: 10),
                  Expanded(child: _block(color, height: 52)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  6,
                  (_) => _block(color, width: 72, height: 32, radius: 18),
                ),
              ),
              const SizedBox(height: 18),
              _block(color, height: 250, radius: 14),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _block(color, height: 90, radius: 14)),
            const SizedBox(width: 12),
            Expanded(child: _block(color, height: 90, radius: 14)),
          ],
        ),
      ],
    );
  }

  Widget _profile(Color color) {
    return ListView(
      key: const ValueKey('skeleton-profile'),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _block(color, width: 70, height: 70, radius: 35),
              const SizedBox(width: 16),
              _lineGroup(color, titleWidth: 155),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _block(color, height: 64, radius: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form(Color color) {
    return ListView(
      key: const ValueKey('skeleton-form'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _block(color, width: 180, height: 22, radius: 7),
        const SizedBox(height: 22),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _block(color, height: 58, radius: 12),
          ),
        ),
        _block(color, height: 48, radius: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'กำลังโหลดข้อมูล',
      liveRegion: true,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final color = Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFFF8FAFC),
              _controller.value,
            )!;
            return switch (widget.layout) {
              AppSkeletonLayout.cards => _cards(color),
              AppSkeletonLayout.report => _report(color),
              AppSkeletonLayout.profile => _profile(color),
              AppSkeletonLayout.form => _form(color),
              AppSkeletonLayout.list => _list(color),
            };
          },
        ),
      ),
    );
  }
}
