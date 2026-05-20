import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_apps/widgets/result/date_preset.dart';
import 'package:safety_apps/widgets/result/page_style.dart';

class ResultDateFilterBar extends StatelessWidget {
  final DatePreset datePreset;
  final DateTimeRange? range;
  final bool exporting;
  final int filteredLength;
  final bool canCurrentUserDownloadExcel;
  final VoidCallback onOpenDateFilterModal;
  final VoidCallback onExportExcel;
  final VoidCallback onNoExcelAccess;
  final Future<void> Function(DatePreset p) onTapPreset;

  const ResultDateFilterBar({
    super.key,
    required this.datePreset,
    required this.range,
    required this.exporting,
    required this.filteredLength,
    required this.canCurrentUserDownloadExcel,
    required this.onOpenDateFilterModal,
    required this.onExportExcel,
    required this.onNoExcelAccess,
    required this.onTapPreset,
  });

  String _rangeLabel() {
    if (datePreset == DatePreset.all) return "Semua tanggal";
    if (datePreset == DatePreset.today) return "Hari ini";
    if (datePreset == DatePreset.week) return "Minggu ini";
    if (datePreset == DatePreset.month) return "Bulan ini";
    if (range == null) return "Pilih range";
    final f = DateFormat("dd MMM yyyy");
    return "${f.format(range!.start)} - ${f.format(range!.end.subtract(const Duration(days: 1)))}";
  }

  @override
  Widget build(BuildContext context) {
    final rangeLabel = _rangeLabel();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [ResultPageStyle.primary.withOpacity(0.10), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter Tanggal",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                        _PresetChipAnimated(
                          label: "Semua",
                          p: DatePreset.all,
                          selectedPreset: datePreset,
                          onTapPreset: onTapPreset,
                        ),
                        _PresetChipAnimated(
                          label: "Hari ini",
                          p: DatePreset.today,
                          selectedPreset: datePreset,
                          onTapPreset: onTapPreset,
                        ),
                        _PresetChipAnimated(
                          label: "Minggu ini",
                          p: DatePreset.week,
                          selectedPreset: datePreset,
                          onTapPreset: onTapPreset,
                        ),
                        _PresetChipAnimated(
                          label: "Bulan ini",
                          p: DatePreset.month,
                          selectedPreset: datePreset,
                          onTapPreset: onTapPreset,
                        ),
                        _PresetChipAnimated(
                          label: "Custom",
                          p: DatePreset.custom,
                          selectedPreset: datePreset,
                          onTapPreset: onTapPreset,
                        ),
                      ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: e,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxWidth < 420;
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onOpenDateFilterModal,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              color: Colors.black.withOpacity(0.65),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rangeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black.withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: (filteredLength == 0 || exporting)
                          ? null
                          : () {
                              if (!canCurrentUserDownloadExcel) {
                                onNoExcelAccess();
                                return;
                              }
                              onExportExcel();
                            },
                      child: Opacity(
                        opacity: (filteredLength == 0 || exporting) ? 0.55 : 1,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1D6F42), Color(0xFF4AC488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ResultPageStyle.primary.withOpacity(
                                  0.25,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    exporting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.download_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                    const SizedBox(width: 8),
                                    Text(
                                      compact ? "Excel" : "Download Excel",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PresetChipAnimated extends StatelessWidget {
  final String label;
  final DatePreset p;
  final DatePreset selectedPreset;
  final Future<void> Function(DatePreset p) onTapPreset;

  const _PresetChipAnimated({
    required this.label,
    required this.p,
    required this.selectedPreset,
    required this.onTapPreset,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedPreset == p;

    return GestureDetector(
      onTap: () async {
        if (selectedPreset == p) return;
        await onTapPreset(p);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected ? ResultPageStyle.primaryGradient : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ResultPageStyle.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: selected ? Colors.white : Colors.black.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
