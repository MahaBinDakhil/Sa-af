import 'package:flutter/material.dart';

import 'scan_page.dart';
import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';

enum ThumbnailKind {
  blackScorch,
  healthy,
  manganese,
  parlatoria,
}

class DiagnosisCase {
  const DiagnosisCase({
    required this.title,
    required this.status,
    required this.date,
    required this.percent,
    required this.thumbnail,
  });

  final String title;
  final String status;
  final String date;
  final int percent;
  final ThumbnailKind thumbnail;

  bool get isHealthy => status == 'Healthy';
}

const List<DiagnosisCase> diagnosisCases = [
  DiagnosisCase(
    title: 'Black Scorch',
    status: 'Diseased',
    date: 'Today, 8:02 AM',
    percent: 98,
    thumbnail: ThumbnailKind.blackScorch,
  ),
  DiagnosisCase(
    title: 'Healthy',
    status: 'Healthy',
    date: 'Yesterday, 2:15 PM',
    percent: 95,
    thumbnail: ThumbnailKind.healthy,
  ),
  DiagnosisCase(
    title: 'Manganese Deficiency',
    status: 'Diseased',
    date: '22 August',
    percent: 90,
    thumbnail: ThumbnailKind.manganese,
  ),
  DiagnosisCase(
    title: 'Parlatoria Blanchardi',
    status: 'Diseased',
    date: '1 August',
    percent: 96,
    thumbnail: ThumbnailKind.parlatoria,
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openDiagnosisHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DiagnosisHistoryPage(),
      ),
    );
  }

  void _openScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScanPage(),
      ),
    );
  }

  void _showDiagnosisPrompt(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start diagnosis',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Image upload is not enabled in this standalone preview. '
                  'You can view one of the sample diagnoses below.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showDiagnosisDetails(context, diagnosisCases.first);
                    },
                    child: const Text('View sample diagnosis'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerHeight = (screenWidth * 0.49).clamp(175.0, 205.0).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              onNotificationsTap: () =>
                  _showMessage(context, "You're all caught up."),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroBanner(
                      height: bannerHeight,
                      onDiagnoseTap: () => _showDiagnosisPrompt(context),
                    ),
                    const SizedBox(height: 26),
                    const SummaryRow(),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Last diagnosis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openDiagnosisHistory(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.mutedText,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Show all',
                                style: TextStyle(fontSize: 12),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ...diagnosisCases.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DiagnosisCard(
                          item: item,
                          onTap: () => showDiagnosisDetails(context, item),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        current: NavTab.home,
        onHomeTap: () {},
        onChatbotTap: () =>
            _showMessage(context, 'Chatbot is a demo placeholder.'),
        onFrameTap: () => _openScan(context),
        onHistoryTap: () => _openDiagnosisHistory(context),
        onSettingsTap: () =>
            _showMessage(context, 'Settings are not available yet.'),
      ),
    );
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key, required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Home',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.height,
    required this.onDiagnoseTap,
  });

  final double height;
  final VoidCallback onDiagnoseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/palm.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 12, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 0.62 * MediaQuery.sizeOf(context).width - 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Is your Date Palm\nlooking healthy?',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.12,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Scan or use images of your date\npalm to identify issues',
                      style: TextStyle(
                        color: Color(0xFFE8F0E9),
                        height: 1.5,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: onDiagnoseTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F2EF),
                          foregroundColor: AppColors.forest,
                          padding: const EdgeInsets.symmetric(horizontal: 19),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Diagnose Now!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: SummaryCard(
            value: '5',
            label: 'Discovered Cases',
            valueColor: AppColors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            value: '6',
            label: 'Healthy palms',
            valueColor: AppColors.leafGreen,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            value: '11',
            label: 'Total diagnosis',
            valueColor: AppColors.forest,
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 21,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final DiagnosisCase item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.isHealthy ? AppColors.leafGreen : AppColors.orange;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 53,
                    height: 53,
                    child: CustomPaint(
                      painter: ThumbnailPainter(item.thumbnail),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF202220),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          StatusTag(
                            label: item.status,
                            isHealthy: item.isHealthy,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.date,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.percent / 100,
                                minHeight: 4,
                                backgroundColor: AppColors.line,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${item.percent}%',
                            style: const TextStyle(
                              color: Color(0xFF292B29),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.isHealthy,
  });

  final String label;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.leafGreen : AppColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          height: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class DiagnosisHistoryPage extends StatelessWidget {
  const DiagnosisHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis history'),
        backgroundColor: AppColors.background,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: diagnosisCases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = diagnosisCases[index];
          return DiagnosisCard(
            item: item,
            onTap: () => showDiagnosisDetails(context, item),
          );
        },
      ),
    );
  }
}

void showDiagnosisDetails(BuildContext context, DiagnosisCase item) {
  final color = item.isHealthy ? AppColors.leafGreen : AppColors.orange;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusTag(
                    label: item.status,
                    isHealthy: item.isHealthy,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                item.date,
                style: const TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.percent / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.line,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${item.percent}% match',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Sample result shown for this standalone interface preview.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Placeholder drawings for the diagnosis card thumbnails.
class ThumbnailPainter extends CustomPainter {
  const ThumbnailPainter(this.kind);

  final ThumbnailKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundColors = switch (kind) {
      ThumbnailKind.blackScorch => const [
          Color(0xFF432F25),
          Color(0xFFB87938),
        ],
      ThumbnailKind.healthy => const [
          Color(0xFF315C3B),
          Color(0xFF87A878),
        ],
      ThumbnailKind.manganese => const [
          Color(0xFF344D30),
          Color(0xFF9B7840),
        ],
      ThumbnailKind.parlatoria => const [
          Color(0xFF66735E),
          Color(0xFFC4C7A9),
        ],
    };

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColors,
        ).createShader(rect),
    );

    if (kind == ThumbnailKind.blackScorch) {
      final fruit = Rect.fromCenter(
        center: Offset(size.width * 0.53, size.height * 0.56),
        width: size.width * 0.52,
        height: size.height * 0.75,
      );
      canvas.drawOval(fruit, Paint()..color = const Color(0xFFC77935));
      for (int i = 0; i < 8; i++) {
        final x = size.width * (0.34 + (i % 3) * 0.12);
        final y = size.height * (0.26 + (i ~/ 3) * 0.18);
        canvas.drawCircle(
          Offset(x, y),
          size.width * (0.035 + (i % 2) * 0.018),
          Paint()..color = const Color(0xFF50352A).withValues(alpha: 0.9),
        );
      }
      canvas.drawLine(
        Offset(size.width * 0.54, size.height * 0.17),
        Offset(size.width * 0.58, size.height * 0.31),
        Paint()
          ..color = const Color(0xFF533D29)
          ..strokeWidth = 2,
      );
    } else if (kind == ThumbnailKind.healthy) {
      for (int i = 0; i < 5; i++) {
        final path = Path()
          ..moveTo(size.width * (0.08 + i * 0.05), size.height * 0.92)
          ..quadraticBezierTo(
            size.width * (0.39 + i * 0.07),
            size.height * 0.47,
            size.width * (0.98 - i * 0.07),
            size.height * (0.12 + i * 0.09),
          );
        canvas.drawPath(
          path,
          Paint()
            ..color = i.isEven
                ? const Color(0xFF244D31)
                : const Color(0xFF91B270)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawLine(
        Offset(size.width * 0.14, size.height * 0.86),
        Offset(size.width * 0.88, size.height * 0.18),
        Paint()
          ..color = const Color(0xFFD0D4A1)
          ..strokeWidth = 1,
      );
    } else if (kind == ThumbnailKind.manganese) {
      for (int i = -2; i < 9; i++) {
        canvas.drawLine(
          Offset(size.width * (i * 0.20), size.height),
          Offset(size.width * (i * 0.20 + 0.85), 0),
          Paint()
            ..color = i.isEven
                ? const Color(0xFF405431)
                : const Color(0xFFB18441)
            ..strokeWidth = 3,
        );
      }
      canvas.drawLine(
        Offset(0, size.height * 0.76),
        Offset(size.width, size.height * 0.68),
        Paint()
          ..color = const Color(0xFF6F6334)
          ..strokeWidth = 3,
      );
    } else {
      final leaf = Path()
        ..moveTo(size.width * 0.05, size.height * 0.65)
        ..quadraticBezierTo(
          size.width * 0.34,
          size.height * 0.07,
          size.width * 0.94,
          size.height * 0.32,
        )
        ..quadraticBezierTo(
          size.width * 0.79,
          size.height * 0.89,
          size.width * 0.05,
          size.height * 0.65,
        );
      canvas.drawPath(leaf, Paint()..color = const Color(0xFF9EA98A));
      canvas.drawLine(
        Offset(size.width * 0.10, size.height * 0.67),
        Offset(size.width * 0.88, size.height * 0.34),
        Paint()
          ..color = const Color(0xFFE0DCC1)
          ..strokeWidth = 1.4,
      );
      for (int i = 0; i < 7; i++) {
        canvas.drawCircle(
          Offset(
            size.width * (0.28 + (i % 3) * 0.15),
            size.height * (0.39 + (i ~/ 3) * 0.10),
          ),
          size.width * 0.035,
          Paint()..color = const Color(0xFFE9E3CC),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ThumbnailPainter oldDelegate) {
    return oldDelegate.kind != kind;
  }
}
