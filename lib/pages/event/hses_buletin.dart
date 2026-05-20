import 'package:flutter/material.dart';
import 'package:safety_apps/models/buletin.dart';
import 'package:safety_apps/service/event/buletin_service.dart';
import 'package:safety_apps/session/auth_session.dart';
import 'package:safety_apps/widgets/event/buletin/buletin_card.dart';
import 'package:safety_apps/widgets/event/buletin/buletin_dialog.dart';
import 'package:safety_apps/widgets/event/buletin/buletin_dialog_review.dart';
import 'package:safety_apps/widgets/event/buletin/buletin_empty.dart';

class HSESBuletinPage extends StatefulWidget {
  final int? openDetailId;

  const HSESBuletinPage({super.key, this.openDetailId});

  @override
  State<HSESBuletinPage> createState() => _HSESBuletinPageState();
}

enum _BuletinFilter { terbaru, butuhReview, selesai }

class _HSESBuletinPageState extends State<HSESBuletinPage> {
  // === UI DAILYPLAN STYLE ===
  static const Color _primary = Color(0xff1d63ff);
  static const Color _secondary = Color(0xff4fa9ff);
  static const Color _bg = Color(0xffeef2f7);
  static const Color _surface = Colors.white;

  List<Buletin> _buletins = [];
  bool _loading = false;
  bool isAdmin = false;

  bool _openedFromNotif = false;

  final TextEditingController _searchCtrl = TextEditingController();
  _BuletinFilter _filter = _BuletinFilter.terbaru;

  @override
  void initState() {
    super.initState();
    isAdmin = AuthSession.isAdmin;
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // === LOGIC PERSIS DAILYPLAN (tapi versi buletin) ===
  bool _canReview(Buletin b) {
    final role = (b.createdByRole ?? '').toLowerCase();

    if (AuthSession.isMember) return true;
    if (AuthSession.isAdmin && role == 'superadmin') return true;

    return false;
  }

  bool _sudahReview(Buletin b) {
    return (b.rating ?? 0) > 0 && (b.comment?.trim().isNotEmpty ?? false);
  }

  // ===== TIME FILTER (UI-only) =====
  String _timeFilter =
      "all"; // all | today | yesterday | this_week | last_week | this_month | last_month | custom
  DateTimeRange? _customRange;

  bool get _hasTimeFilter => _timeFilter != "all";

  // === SEARCH + FILTER + SORT (UI logic saja) ===
  List<Buletin> get _visibleBuletins {
    final q = _searchCtrl.text.toLowerCase().trim();

    List<Buletin> list = List<Buletin>.from(_buletins);

    // 1) filter chip
    if (_filter == _BuletinFilter.butuhReview) {
      list = list.where((b) => _canReview(b) && !_sudahReview(b)).toList();
    } else if (_filter == _BuletinFilter.selesai) {
      list = list.where((b) => _sudahReview(b)).toList();
    }

    list = list.where(_matchTimeFilter).toList();

    // 2) search filter
    List<Buletin> filtered = list.where((b) {
      if (q.isEmpty) return true;

      final title = (b.title).toLowerCase();
      final sub = (b.subtitle).toLowerCase();
      final desc = (b.description).toLowerCase();

      return title.contains(q) || sub.contains(q) || desc.contains(q);
    }).toList();

    // 3) search ranking (persis pola dailyplan kamu)
    if (q.isNotEmpty) {
      int rankText(String text) {
        if (text.startsWith(q)) return 0;

        final wholeWord = RegExp(
          r'(^|[\s\W])' + RegExp.escape(q) + r'([\s\W]|$)',
        );
        if (wholeWord.hasMatch(text)) return 1;

        if (text.contains(q)) return 2;
        return 3;
      }

      int rankBuletin(Buletin b) {
        final t = b.title.toLowerCase();
        final s = b.subtitle.toLowerCase();
        final d = b.description.toLowerCase();
        final rt = rankText(t);
        final rs = rankText(s);
        final rd = rankText(d);
        return [rt, rs, rd].reduce((a, c) => a < c ? a : c);
      }

      int firstIndex(Buletin b) {
        final t = b.title.toLowerCase();
        final s = b.subtitle.toLowerCase();
        final d = b.description.toLowerCase();

        int idx(String x) => x.indexOf(q);
        final it = idx(t);
        final isub = idx(s);
        final id = idx(d);

        int best = 1 << 30;
        if (it >= 0) best = it < best ? it : best;
        if (isub >= 0) best = isub < best ? isub : best;
        if (id >= 0) best = id < best ? id : best;

        return best == (1 << 30) ? 1 << 29 : best;
      }

      filtered.sort((a, b) {
        final ra = rankBuletin(a);
        final rb = rankBuletin(b);
        if (ra != rb) return ra.compareTo(rb);

        final ia = firstIndex(a);
        final ib = firstIndex(b);
        if (ia != ib) return ia.compareTo(ib);

        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    // 4) sort terbaru (kalau chip terbaru dan q kosong)
    if (_filter == _BuletinFilter.terbaru && q.isEmpty) {
      filtered.sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    }

    return filtered;
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  String _timeFilterLabel() {
    switch (_timeFilter) {
      case "today":
        return "Hari ini";
      case "yesterday":
        return "Kemarin";
      case "this_week":
        return "Minggu ini";
      case "last_week":
        return "Minggu lalu";
      case "this_month":
        return "Bulan ini";
      case "last_month":
        return "Bulan lalu";
      case "custom":
        if (_customRange == null) return "Custom";
        final a = formatDate(_customRange!.start);
        final b = formatDate(_customRange!.end);
        return "$a • $b";
      default:
        return "Semua waktu";
    }
  }

  bool _matchTimeFilter(Buletin p) {
    if (_timeFilter == "all") return true;

    final dt = p.createdAt;
    if (dt == null) return false;

    final now = DateTime.now();
    final today = _startOfDay(now);
    final date = _startOfDay(dt);

    if (_timeFilter == "today") {
      return date == today;
    }

    if (_timeFilter == "yesterday") {
      return date == today.subtract(const Duration(days: 1));
    }

    if (_timeFilter == "this_week") {
      final startOfThisWeek = today.subtract(
        Duration(days: today.weekday - 1),
      ); // Senin
      final endOfThisWeek = startOfThisWeek.add(
        const Duration(days: 7),
      ); // eksklusif
      return !date.isBefore(startOfThisWeek) && date.isBefore(endOfThisWeek);
    }

    if (_timeFilter == "last_week") {
      final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
      return !date.isBefore(startOfLastWeek) && date.isBefore(startOfThisWeek);
    }

    if (_timeFilter == "this_month") {
      final startThisMonth = _startOfMonth(today);
      final startNextMonth = DateTime(
        startThisMonth.year,
        startThisMonth.month + 1,
        1,
      );
      return !date.isBefore(startThisMonth) && date.isBefore(startNextMonth);
    }

    if (_timeFilter == "last_month") {
      final startThisMonth = _startOfMonth(today);
      final startLastMonth = DateTime(
        startThisMonth.year,
        startThisMonth.month - 1,
        1,
      );
      return !date.isBefore(startLastMonth) && date.isBefore(startThisMonth);
    }

    if (_timeFilter == "custom") {
      final r = _customRange;
      if (r == null) return true;

      // include sampai akhir hari end (biar natural)
      final start = _startOfDay(r.start);
      final endExclusive = _startOfDay(r.end).add(const Duration(days: 1));
      return !date.isBefore(start) && date.isBefore(endExclusive);
    }

    return true;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final data = await HSESBuletinService.fetchAll();

      if (!mounted) return;

      setState(() {
        _buletins = data;
        _loading = false;
      });

      if (widget.openDetailId != null && !_openedFromNotif) {
        Buletin? buletin;

        try {
          buletin = _buletins.firstWhere((e) => e.id == widget.openDetailId);
        } catch (_) {
          buletin = null;
        }

        if (buletin != null) {
          _openedFromNotif = true;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final updated = await showBuletinDetailDialog(
              context,
              buletin: buletin!,
            );

            if (updated != null && mounted) {
              await _loadData();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("ERROR LOAD: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleBuletins;

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.22),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "HSES Buletin",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: [
                  _heroHeader(total: _buletins.length),

                  const SizedBox(height: 14),

                  _searchBar(),

                  const SizedBox(height: 12),

                  _timeFilterBar(),

                  const SizedBox(height: 12),

                  _filterChips(),

                  const SizedBox(height: 18),

                  if (visible.isEmpty)
                    const BuletinEmpty()
                  else
                    Column(
                      children: visible.map((buletin) {
                        return BuletinCard(
                          buletin: buletin,
                          onEdit: () async {
                            final edited = await showBuletinDialog(
                              context,
                              buletin: buletin,
                              userRole: AuthSession.role!,
                              userSiteId: AuthSession.siteId!,
                            );

                            if (edited != null && mounted) {
                              await _loadData();

                              if (!mounted) return;

                              showAutoInfoDialog(
                                context,
                                title: "Berhasil",
                                message:
                                    "Buletin berhasil diperbarui & notifikasi terkirim",
                                icon: Icons.check_circle_rounded,
                              );
                            }
                          },
                          onDelete: () async {
                            final success = await HSESBuletinService.delete(
                              buletin.id,
                            );
                            if (success && mounted) {
                              await _loadData();

                              if (!mounted) return;

                              showAutoInfoDialog(
                                context,
                                title: "Berhasil",
                                message: "Buletin berhasil dihapus",
                                icon: Icons.delete_forever_rounded,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "© ${DateTime.now().year} SAFE DAY • HSES Management System",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await showBuletinDialog(
                  context,
                  userRole: AuthSession.role!,
                  userSiteId: AuthSession.siteId!,
                );

                if (result != null && mounted) {
                  await _loadData();

                  if (!mounted) return;

                  showAutoInfoDialog(
                    context,
                    title: "Berhasil",
                    message: "Buletin berhasil dibuat & notifikasi terkirim",
                    icon: Icons.check_circle_rounded,
                  );
                }
              },
              backgroundColor: _primary,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Tambah Buletin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            )
          : null,
    );
  }

  Widget _heroHeader({required int total}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_secondary.withOpacity(0.95), _primary.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Informasi & Edukasi Safety",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "HSES Buletin",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  "$total",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Cari buletin (judul / subjudul / deskripsi) …",
          hintStyle: const TextStyle(
            color: Colors.black45,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _primary.withOpacity(0.9),
          ),
          suffixIcon: _searchCtrl.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(() => _searchCtrl.clear()),
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        onChanged: (_) => setState(() {}), // realtime persis dailyplan
      ),
    );
  }

  Widget _filterChips() {
    Widget chip({
      required _BuletinFilter type,
      required String text,
      required IconData icon,
    }) {
      final selected = _filter == type;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _filter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [_primary, _secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.06),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : _primary.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            type: _BuletinFilter.terbaru,
            text: "Terbaru",
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(width: 10),
          chip(
            type: _BuletinFilter.butuhReview,
            text: "Butuh Review",
            icon: Icons.rate_review_rounded,
          ),
          const SizedBox(width: 10),
          chip(
            type: _BuletinFilter.selesai,
            text: "Selesai",
            icon: Icons.verified_rounded,
          ),
        ],
      ),
    );
  }

  Widget _timeFilterBar() {
    final border = Colors.black.withOpacity(0.06);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _openTimeFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [_primary, _secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Filter Waktu",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeFilterLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasTimeFilter)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _primary.withOpacity(0.22)),
                      ),
                      child: const Text(
                        "AKTIF",
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_hasTimeFilter) ...[
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() {
              _timeFilter = "all";
              _customRange = null;
            }),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  void _openTimeFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Widget pill({
              required String key,
              required String text,
              required IconData icon,
            }) {
              final selected = _timeFilter == key;

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _timeFilter = key;
                    if (key != "custom") _customRange = null;
                  });
                  setSheet(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: selected
                        ? const LinearGradient(
                            colors: [_primary, _secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : const Color(0xffeef2f7),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: selected
                            ? Colors.white
                            : _primary.withOpacity(0.85),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }

            Future<void> pickCustomRange() async {
              final now = DateTime.now();
              final initial =
                  _customRange ??
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 7)),
                    end: now,
                  );

              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 3, 1, 1),
                lastDate: DateTime(now.year + 1, 12, 31),
                initialDateRange: initial,
                helpText: "Pilih Rentang Tanggal",
                confirmText: "Pakai",
                saveText: "Pakai",
              );

              if (picked != null && mounted) {
                setState(() {
                  _timeFilter = "custom";
                  _customRange = picked;
                });
                setSheet(() {});
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Filter Waktu",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _timeFilter = "all";
                                  _customRange = null;
                                });
                                setSheet(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: const Text(
                                  "Reset",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // quick presets
                        pill(
                          key: "all",
                          text: "Semua waktu",
                          icon: Icons.all_inclusive_rounded,
                        ),
                        const SizedBox(height: 10),
                        pill(
                          key: "today",
                          text: "Hari ini",
                          icon: Icons.today_rounded,
                        ),
                        const SizedBox(height: 10),
                        pill(
                          key: "yesterday",
                          text: "Kemarin",
                          icon: Icons.history_toggle_off_rounded,
                        ),
                        const SizedBox(height: 10),
                        pill(
                          key: "this_week",
                          text: "Minggu ini",
                          icon: Icons.date_range_rounded,
                        ),
                        const SizedBox(height: 10),
                        pill(
                          key: "last_week",
                          text: "Minggu lalu",
                          icon: Icons.event_repeat_rounded,
                        ),
                        const SizedBox(height: 10),
                        pill(
                          key: "this_month",
                          text: "Bulan ini",
                          icon: Icons.calendar_view_month_rounded,
                        ),
                        const SizedBox(height: 10),
                        pill(
                          key: "last_month",
                          text: "Bulan lalu",
                          icon: Icons.calendar_month_rounded,
                        ),

                        const SizedBox(height: 12),

                        // custom range
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            await pickCustomRange();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: _primary.withOpacity(0.06),
                              border: Border.all(
                                color: _primary.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: _primary.withOpacity(0.9),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "Custom range",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  _timeFilter == "custom"
                                      ? _timeFilterLabel()
                                      : "Pilih",
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.55),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black.withOpacity(0.45),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Terapkan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// === AUTO INFO DIALOG: SAMAKAN PERSIS DAILYPLAN (ukuran 72) ===
void showAutoInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.check_circle_rounded,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop();
        }
      });

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff1d63ff).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
