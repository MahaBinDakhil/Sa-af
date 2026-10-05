import 'package:flutter/material.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  static const Color primaryGreen = Color(0xFF1F6B45);
  static const Color darkGreen = Color(0xFF17372A);
  static const Color backgroundColor = Color(0xFFF7F8F2);
  static const Color lightGreen = Color(0xFFEAF2E9);
  static const Color textGrey = Color(0xFF66756D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // TOP BAR
              // =========================================================
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Analysis result',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.share_outlined,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================================================
              // ANALYZED IMAGE
              // =========================================================
              Container(
                height: 172,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFDDE7D9),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Temporary image/design placeholder.
                    // Later we will replace this with the image
                    // captured from the Camera page.
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFBFC9B4),
                            Color(0xFFE7E8D7),
                            Color(0xFF9DA786),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.eco_outlined,
                          size: 80,
                          color: Color(0xFF65735E),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: darkGreen.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Analyzed just now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =========================================================
              // PREDICTION CARD
              // =========================================================
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0DC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            color: Color(0xFFF18B20),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PREDICTION',
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Graphiola Leaf Spot',
                              style: TextStyle(
                                color: darkGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Divider(
                      color: Colors.grey.shade200,
                      height: 1,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CONFIDENCE',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                '94.7%',
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'SEVERITY',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDD8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Moderate',
                                  style: TextStyle(
                                    color: Color(0xFFD87518),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _ConfidenceCircle(),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 49),
                              const Text(
                                'PALM',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Palm #02',
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =========================================================
              // ABOUT THIS DISEASE
              // =========================================================
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: 'About this disease',
                      icon: Icons.info_outline,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Graphiola Leaf Spot is a fungal disease that can '
                      'affect date palm leaves. Early monitoring helps '
                      'prevent damage from spreading.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Common symptoms',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _CheckItem(
                      text: 'Brown or black spots on leaves',
                    ),
                    _CheckItem(
                      text: 'Yellowing or discoloration',
                    ),
                    _CheckItem(
                      text: 'Visible lesions',
                    ),
                    _CheckItem(
                      text: 'Reduced leaf health',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =========================================================
              // EFFECTS ON YOUR PALM
              // =========================================================
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Effects on your palm',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'If symptoms progress, affected leaves may lose '
                      'vitality and photosynthetic activity. Severe damage '
                      'can impact overall palm productivity.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =========================================================
              // RECOMMENDED TREATMENT
              // =========================================================
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended treatment & care',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _NumberedItem(
                      number: '1',
                      text: 'Inspect affected leaves regularly',
                    ),

                    _NumberedItem(
                      number: '2',
                      text:
                          'Remove severely affected material when appropriate',
                    ),

                    _NumberedItem(
                      number: '3',
                      text: 'Maintain appropriate irrigation',
                    ),

                    _NumberedItem(
                      number: '4',
                      text: 'Keep the surrounding area clean',
                    ),

                    _NumberedItem(
                      number: '5',
                      text: 'Monitor for spreading symptoms',
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: primaryGreen,
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recommended next step: scan this palm again in 7 days.',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 10,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =========================================================
              // DISCLAIMER
              // =========================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF9AA69E),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AI predictions are intended for preliminary assessment '
                      'and should not replace professional agricultural diagnosis.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================================================
              // SAVE TO MY PALM
              // =========================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Save to my palm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =========================================================
              // ASK AI
              // =========================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: primaryGreen,
                    size: 19,
                  ),
                  label: const Text(
                    'Ask AI about this result',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =========================================================
              // SCAN AGAIN
              // =========================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: primaryGreen,
                    size: 19,
                  ),
                  label: const Text(
                    'Scan again',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// WHITE CARD
// ===========================================================================

class _WhiteCard extends StatelessWidget {
  final Widget child;

  const _WhiteCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECE6),
        ),
      ),
      child: child,
    );
  }
}

// ===========================================================================
// SECTION TITLE
// ===========================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AnalysisResultScreen.darkGreen,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(
          icon,
          color: const Color(0xFF87938C),
          size: 17,
        ),
      ],
    );
  }
}

// ===========================================================================
// CHECK ITEM
// ===========================================================================

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check,
            color: AnalysisResultScreen.primaryGreen,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AnalysisResultScreen.textGrey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// NUMBERED ITEM
// ===========================================================================

class _NumberedItem extends StatelessWidget {
  final String number;
  final String text;

  const _NumberedItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AnalysisResultScreen.primaryGreen,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AnalysisResultScreen.textGrey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CONFIDENCE CIRCLE
// ===========================================================================

class _ConfidenceCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              value: 0.95,
              strokeWidth: 5,
              backgroundColor: const Color(0xFFDDEBE0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AnalysisResultScreen.primaryGreen,
              ),
            ),
          ),
          const Text(
            '95%',
            style: TextStyle(
              color: AnalysisResultScreen.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CIRCLE ICON BUTTON
// ===========================================================================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE3E8E1),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5D6D64),
            size: 18,
          ),
        ),
      ),
    );
  }
}