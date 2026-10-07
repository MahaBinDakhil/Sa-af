import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'chatbot.dart';
import 'scan_page.dart';

// ============================================================
// COLORS
// ============================================================

class HistoryColors {
  static const Color background = Color(0xFFF8F9F8);
  static const Color forest = Color(0xFF3F664D);
  static const Color leaf = Color(0xFF6FA780);
  static const Color orange = Color(0xFFC96D32);
  static const Color diseasedChip = Color(0xFFD9A073);
  static const Color muted = Color(0xFF777A78);
  static const Color line = Color(0xFFE1E2E1);
  static const Color text = Color(0xFF171817);
}

// ============================================================
// MODEL: سجل فحص واحد
// ============================================================

class ScanRecord {
  ScanRecord({
    required this.id,
    required this.title,
    required this.isHealthy,
    required this.date,
    required this.confidence,
    this.diseaseId = '',
    this.description = '',
    this.imageUrl,
    this.heatmapUrl,
    this.regionUrl,
    double? healthConfidence,
    double? typeConfidence,
  })  : healthConfidence = healthConfidence ?? confidence,
        typeConfidence = typeConfidence ?? confidence;

  final String id;
  final String title;
  final bool isHealthy;
  final DateTime date;
  final double confidence; // من 0 إلى 100
  final String diseaseId; // يتمرر للشات بوت
  final String description;
  final String? imageUrl;
  final String? heatmapUrl;
  final String? regionUrl;
  final double healthConfidence;
  final double typeConfidence;
}

// ============================================================
// FIRESTORE: users/{uid}/scans
// ============================================================

class HistoryRepository {
  final Map<String, String> _descCache = {};

  CollectionReference<Map<String, dynamic>> get _scans {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please log in first');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scans');
  }

  Stream<List<ScanRecord>> watchScans() {
    try {
      // ملاحظة: Firestore يتجاهل أي مستند ما فيه حقل createdAt
      return _scans
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snap) async {
        final list = <ScanRecord>[];
        for (final d in snap.docs) {
          list.add(await _fromDoc(d));
        }
        return list;
      });
    } catch (e) {
      return Stream.error(e);
    }
  }

  Future<void> deleteScan(String id) => _scans.doc(id).delete();

  double _pct(dynamic v) {
    final n = (v as num?)?.toDouble() ?? 0;
    return n <= 1 ? n * 100 : n;
  }

  String? _url(dynamic v) {
    final s = (v ?? '').toString();
    return (s.startsWith('http') && s.length > 8) ? s : null;
  }

  Future<String> _description(String diseaseId) async {
    if (diseaseId.isEmpty) return '';
    final cached = _descCache[diseaseId];
    if (cached != null) return cached;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('diseases')
          .doc(diseaseId)
          .get();
      final text = (doc.data()?['description'] ?? '').toString();
      _descCache[diseaseId] = text;
      return text;
    } catch (_) {
      return '';
    }
  }

  Future<ScanRecord> _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> d) async {
    final j = d.data();
    final diseaseId = (j['diseaseId'] ?? '').toString();
    final isHealthy =
        (j['status'] ?? '').toString().toLowerCase() == 'healthy' ||
            diseaseId == 'healthy';
    final conf = _pct(j['confidence']);

    // خطوات XAI من قائمة predictions
    double typeConf = conf;
    double healthConf = conf;
    final preds = j['predictions'];
    if (preds is List && preds.isNotEmpty) {
      final first = preds.first;
      if (first is Map) typeConf = _pct(first['score']);
      if (!isHealthy) {
        for (final p in preds) {
          if (p is Map && p['name'].toString().toLowerCase() == 'healthy') {
            healthConf = 100 - _pct(p['score']);
          }
        }
      }
    }

    var desc = await _description(diseaseId);
    if (desc.isEmpty && isHealthy) {
      desc = 'No signs of disease were detected on this palm.';
    }

    return ScanRecord(
      id: d.id,
      title: (j['diseaseName'] ?? j['title'] ?? diseaseId).toString(),
      isHealthy: isHealthy,
      date: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confidence: conf,
      diseaseId: diseaseId,
      description: desc,
      imageUrl: _url(j['imageUrl']),
      heatmapUrl: _url(j['heatmapUrl']),
      regionUrl: _url(j['regionUrl']),
      healthConfidence: healthConf,
      typeConfidence: typeConf,
    );
  }
}

/// تعبّي بيانات تجريبية لحسابك لو ما عندك فحوصات (مرة وحدة فقط).
/// diseaseId لازم يطابق مستندات diseases/ عند الفريق.
Future<void> seedSampleScansIfEmpty() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final col = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('scans');
  if ((await col.limit(1).get()).docs.isNotEmpty) return;

  final now = DateTime.now();
  final samples = <List<Object>>[
    // [diseaseId, الاسم, healthy?, الثقة, قبل كم يوم]
    ['black_scorch', 'Black Scorch', false, 0.98, 0],
    ['healthy', 'Healthy', true, 0.95, 1],
    ['manganese_deficiency', 'Manganese Deficiency', false, 0.90, 30],
    ['parlatoria_blanchardi', 'Parlatoria Blanchardi', false, 0.96, 60],
  ];

  for (final s in samples) {
    final healthy = s[2] as bool;
    final score = s[3] as double;
    await col.add({
      'diseaseId': s[0],
      'diseaseName': s[1],
      'status': healthy ? 'healthy' : 'diseased',
      'confidence': score,
      'createdAt':
          Timestamp.fromDate(now.subtract(Duration(days: s[4] as int))),
      'imageUrl': '',
      'heatmapUrl': '',
      'regionUrl': '',
      'predictions': [
        {'name': s[1], 'score': score},
        {
          'name': healthy ? 'Black Scorch' : 'Healthy',
          'score': double.parse((1 - score).toStringAsFixed(2)),
        },
      ],
    });
  }
}

// ============================================================
// HELPERS: تاريخ، صورة، وسم الحالة
// ============================================================

const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _time(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

/// للقائمة: Today, 8:02 AM / Yesterday, 2:15 PM / 22 August
String formatScanDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today, ${_time(d)}';
  if (diff == 1) return 'Yesterday, ${_time(d)}';
  return '${d.day} ${_months[d.month - 1]}';
}

/// للتفاصيل: 1 August, 10:21 AM
String formatScanDateFull(DateTime d) =>
    '${d.day} ${_months[d.month - 1]}, ${_time(d)}';

/// صورة الفحص. لو ما فيه رابط يطلع لون بديل بدل الخطأ.
class ScanImage extends StatelessWidget {
  const ScanImage({
    super.key,
    this.url,
    this.isHealthy = true,
    this.width,
    this.height,
    this.radius = 8,
  });

  final String? url;
  final bool isHealthy;
  final double? width;
  final double? height;
  final double radius;

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHealthy
              ? const [Color(0xFF315C3B), Color(0xFF87A878)]
              : const [Color(0xFF432F25), Color(0xFFB87938)],
        ),
      ),
      child: const Center(child: Icon(Icons.eco, color: Colors.white54)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    Widget content;
    if (u == null || u.isEmpty) {
      content = _placeholder();
    } else if (u.startsWith('http')) {
      content = Image.network(u,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    } else {
      content = Image.asset(u,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: content),
    );
  }
}

class ScanStatusTag extends StatelessWidget {
  const ScanStatusTag({super.key, required this.isHealthy});
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? HistoryColors.leaf : HistoryColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        isHealthy ? 'Healthy' : 'Diseased',
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

// ============================================================
// SCREEN 1: HISTORY (القائمة)
// ============================================================

enum _Filter { all, healthy, diseased }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repo = HistoryRepository();
  late final Stream<List<ScanRecord>> _stream = _repo.watchScans();
  final TextEditingController _search = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // شغّلي السطر التالي مرة وحدة لتعبئة بيانات تجريبية لحسابك، ثم أعيدي تعليقه:
    // seedSampleScansIfEmpty();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openScan() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanPage()),
    );
  }

  List<ScanRecord> _apply(List<ScanRecord> all) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      final okFilter = _filter == _Filter.all
          ? true
          : _filter == _Filter.healthy
              ? r.isHealthy
              : !r.isHealthy;
      final okQuery = q.isEmpty || r.title.toLowerCase().contains(q);
      return okFilter && okQuery;
    }).toList();
  }

  Future<void> _delete(ScanRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6DFCB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: HistoryColors.orange),
              ),
              const SizedBox(height: 16),
              const Text('Delete this scan ?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                "${r.title} - ${formatScanDate(r.date)} will be removed from your history. This can't be undone.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: HistoryColors.muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HistoryColors.text,
                        side: const BorderSide(color: HistoryColors.text),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: HistoryColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) await _repo.deleteScan(r.id);
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child:
                Icon(Icons.notifications, size: 18, color: HistoryColors.text),
          ),
          Column(
            children: [
              const Text('History',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: HistoryColors.text)),
              const SizedBox(height: 2),
              Text('$count scan saved',
                  style: const TextStyle(
                      fontSize: 10, color: HistoryColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by diseases name',
          hintStyle: const TextStyle(fontSize: 12, color: HistoryColors.muted),
          prefixIcon:
              const Icon(Icons.search, size: 18, color: HistoryColors.muted),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: HistoryColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: HistoryColors.forest),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, _Filter f, Color selectedColor) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? selectedColor : HistoryColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.white : HistoryColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _chip('All', _Filter.all, HistoryColors.forest),
          _chip('Healthy', _Filter.healthy, HistoryColors.leaf),
          _chip('Diseased', _Filter.diseased, HistoryColors.diseasedChip),
        ],
      ),
    );
  }

  Widget _card(ScanRecord r) {
    final color = r.isHealthy ? HistoryColors.leaf : HistoryColors.orange;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => ScanDetailsScreen(record: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              ScanImage(
                  url: r.imageUrl,
                  isHealthy: r.isHealthy,
                  width: 53,
                  height: 53,
                  radius: 8),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 7),
                        ScanStatusTag(isHealthy: r.isHealthy),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formatScanDate(r.date),
                        style: const TextStyle(
                            fontSize: 9, color: HistoryColors.muted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: r.confidence / 100,
                              minHeight: 4,
                              backgroundColor: HistoryColors.line,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${r.confidence.round()}%',
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _delete(r),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: HistoryColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFE3E6E1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history,
                  size: 40, color: HistoryColors.forest),
            ),
            const SizedBox(height: 16),
            const Text('No scans yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Scan your first date palm and its\ndiagnosis will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: HistoryColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openScan,
              icon: const Icon(Icons.crop_free, size: 18),
              label: const Text('Start Scan'),
              style: FilledButton.styleFrom(
                backgroundColor: HistoryColors.forest,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: HistoryColors.background,
        body: SafeArea(
          child: StreamBuilder<List<ScanRecord>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('تعذّر تحميل السجل:\n${snap.error}',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data!;
              final shown = _apply(all);
              return Column(
                children: [
                  _header(all.length),
                  if (all.isEmpty)
                    Expanded(child: _emptyState())
                  else ...[
                    _searchField(),
                    _chips(),
                    Expanded(
                      child: shown.isEmpty
                          ? const Center(
                              child: Text('No results',
                                  style:
                                      TextStyle(color: HistoryColors.muted)))
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: shown.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _card(shown[i]),
                            ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        // الشريط يختفي لما يطلع الكيبورد (مثلاً وأنتِ تكتبين في البحث)
        bottomNavigationBar: keyboardOpen
            ? null
            : AppBottomNavigationBar(
                current: NavTab.history,
                onHomeTap: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                onChatbotTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                      builder: (_) => const ChatbotScreen()),
                ),
                onFrameTap: _openScan,
                onHistoryTap: () {},
                onSettingsTap: () {},
              ),
      ),
    );
  }
}

// ============================================================
// SCREEN 2: SCAN DETAILS
// ============================================================

/// يفتح الشات بوت مربوط بنتيجة الفحص.
void _openChatbotFor(BuildContext context, ScanRecord r) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChatbotScreen(
        diseaseId: r.diseaseId,
        confidence: r.confidence / 100, // الشات يتوقع نسبة من 0 إلى 1
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDEDED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left, size: 20),
                ),
              ),
            ),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

const List<BoxShadow> _cardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
];

class ScanDetailsScreen extends StatelessWidget {
  const ScanDetailsScreen({super.key, required this.record});
  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final color = r.isHealthy ? HistoryColors.leaf : HistoryColors.orange;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: HistoryColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const _TopBar(title: 'Scan Details'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScanImage(
                        url: r.imageUrl,
                        isHealthy: r.isHealthy,
                        width: double.infinity,
                        height: 170,
                        radius: 14,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(r.title,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ),
                                ScanStatusTag(isHealthy: r.isHealthy),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 12, color: HistoryColors.muted),
                                const SizedBox(width: 6),
                                Text(formatScanDateFull(r.date),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: HistoryColors.muted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Confidence',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: HistoryColors.muted)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: r.confidence / 100,
                                      minHeight: 4,
                                      backgroundColor: HistoryColors.line,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${r.confidence.round()}%',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('About this disease',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        r.description.isEmpty
                            ? 'No description available.'
                            : r.description,
                        style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            color: HistoryColors.muted),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => XaiExplanationScreen(record: r),
                            ),
                          ),
                          icon:
                              const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('View XAI Explanation'),
                          style: FilledButton.styleFrom(
                            backgroundColor: HistoryColors.forest,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => _openChatbotFor(context, r),
                          icon:
                              const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Ask the Chatbot'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HistoryColors.text,
                            side: const BorderSide(color: HistoryColors.text),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }
}

// ============================================================
// SCREEN 3: XAI EXPLANATION
// ============================================================

class XaiExplanationScreen extends StatefulWidget {
  const XaiExplanationScreen({super.key, required this.record});
  final ScanRecord record;

  @override
  State<XaiExplanationScreen> createState() => _XaiExplanationScreenState();
}

class _XaiExplanationScreenState extends State<XaiExplanationScreen> {
  bool _heatmap = true;

  Widget _toggle() {
    Widget seg(String label, bool value) {
      final sel = _heatmap == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _heatmap = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: sel ? HistoryColors.text : HistoryColors.muted,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                )),
          ),
        ),
      );
    }

    return Container(
      width: 170,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAE9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [seg('Heatmap', true), seg('Region', false)]),
    );
  }

  Widget _legend() {
    const style = TextStyle(fontSize: 8, color: HistoryColors.muted);
    if (_heatmap) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Low', style: style),
          const SizedBox(width: 4),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(colors: [
                Color(0xFF3B5BDB),
                Color(0xFF37B24D),
                Color(0xFFFAB005),
                Color(0xFFE03131),
              ]),
            ),
          ),
          const SizedBox(width: 4),
          const Text('High', style: style),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: const Color(0xFFE03131)),
        const SizedBox(width: 4),
        const Text('High Attention', style: style),
      ],
    );
  }

  Widget _step(int n, String label, String value, double percent, Color c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: Color(0xFFE9EAE9), shape: BoxShape.circle),
          child: Text('$n', style: const TextStyle(fontSize: 9)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, color: HistoryColors.muted)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  Text('${percent.round()}%',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 3,
                  backgroundColor: HistoryColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(c),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final color = r.isHealthy ? HistoryColors.leaf : HistoryColors.orange;
    final imageUrl =
        _heatmap ? (r.heatmapUrl ?? r.imageUrl) : (r.regionUrl ?? r.imageUrl);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: HistoryColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const _TopBar(title: 'XAI Explanation'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScanImage(
                        url: imageUrl,
                        isHealthy: r.isHealthy,
                        width: double.infinity,
                        height: 170,
                        radius: 14,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _toggle(),
                          const Spacer(),
                          _legend(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _heatmap
                            ? "Grad-CAM++ heatmap: red areas are the parts of the photo that influenced the AI's decision the most."
                            : 'Region: the red outline marks the area of the photo the AI paid the most attention to.',
                        style: const TextStyle(
                            fontSize: 10,
                            height: 1.4,
                            color: HistoryColors.text),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('How the AI decided',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            _step(1, 'Health check',
                                r.isHealthy ? 'Healthy' : 'Diseased',
                                r.healthConfidence, color),
                            if (!r.isHealthy) ...[
                              const SizedBox(height: 12),
                              _step(2, 'Disease type', r.title,
                                  r.typeConfidence, color),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Highlighted areas show where the AI looked, not confirmed disease spots. For treatment, check with an agricultural specialist.',
                        style: TextStyle(
                            fontSize: 8,
                            height: 1.4,
                            color: HistoryColors.muted),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => _openChatbotFor(context, r),
                          icon:
                              const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Ask the Chatbot about this'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HistoryColors.text,
                            side: const BorderSide(color: HistoryColors.text),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }
}