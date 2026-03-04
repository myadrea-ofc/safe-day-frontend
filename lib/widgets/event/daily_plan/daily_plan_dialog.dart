import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_apps/models/daily_plan.dart';
import 'package:safety_apps/service/event/daily_plan_service.dart';
import 'package:safety_apps/widgets/input/input_field_daily_plan.dart';
import 'package:safety_apps/widgets/label_text.dart';

Future<DailyPlan?> showDailyPlanDialog(
  BuildContext context, {
  DailyPlan? plan,
  required String userRole,
  required int userSiteId,
  bool readOnly = false,
}) async {
  final titleCtrl = TextEditingController(text: plan?.title ?? '');
  final subCtrl = TextEditingController(text: plan?.subtitle ?? '');
  final descCtrl = TextEditingController(text: plan?.description ?? '');
  final imgCtrl = TextEditingController(
    text: plan?.image != null ? 'Gambar tersimpan' : '',
  );
  final isSubmitting = ValueNotifier<bool>(false);

  File? imageFile;

  bool isForAllSites = false;
  List<int> selectedSiteIds = [];
  List<Map<String, dynamic>> siteList = [];

  if (userRole == "superadmin") {
    siteList = await HSESDailyPlanService.fetchSites();

    if (plan != null) {
      isForAllSites = plan.isForAllSites;
      selectedSiteIds = isForAllSites ? [] : List<int>.from(plan.siteIds);
    }
  }

  bool isNew = plan == null;
  bool isFieldFilled() {
    if (titleCtrl.text.trim().isEmpty ||
        subCtrl.text.trim().isEmpty ||
        descCtrl.text.trim().isEmpty) {
      return false;
    }
    if (isNew && imageFile == null && (plan?.image == null)) {
      return false;
    }
    if (userRole == "superadmin" && !isForAllSites && selectedSiteIds.isEmpty) {
      return false;
    }
    return true;
  }

  return showDialog<DailyPlan>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xffeef2f7),
            insetPadding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff1d63ff), Color(0xff4fa9ff)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            plan == null
                                ? "Tambah Daily Plan"
                                : "Edit Daily Plan",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userRole == "superadmin") ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Berlaku untuk semua site",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isForAllSites,
                                  activeColor: const Color(0xff1d63ff),
                                  onChanged: (val) {
                                    setState(() {
                                      isForAllSites = val;
                                      if (val) selectedSiteIds.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          // ===== Site Chips =====
                          if (!isForAllSites)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: siteList.map((site) {
                                final int id = site["id"];
                                final bool selected = selectedSiteIds.contains(
                                  id,
                                );

                                return FilterChip(
                                  label: Text(
                                    site["site_name"]?.toString().isNotEmpty ==
                                            true
                                        ? site["site_name"].toString()
                                        : site["name"]?.toString() ?? "UNKNOWN",
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  selected: selected,
                                  selectedColor: const Color(0xff1d63ff),
                                  backgroundColor: Colors.grey.shade200,
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      val
                                          ? selectedSiteIds.add(id)
                                          : selectedSiteIds.remove(id);
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 16),
                        ],

                        LabelText("Judul"),
                        InputFieldDailyPlan(
                          controller: titleCtrl,
                          label: "Masukkan Judul",
                          icon: Icons.title,
                        ),

                        SizedBox(height: 14),
                        LabelText("Sub Judul"),
                        InputFieldDailyPlan(
                          controller: subCtrl,
                          label: "Masukkan Sub Judul",
                          icon: Icons.list,
                        ),

                        SizedBox(height: 14),
                        LabelText("Deskripsi Kegiatan"),
                        InputFieldDailyPlan(
                          controller: descCtrl,
                          label: "Masukkan Deskripsi",
                          icon: Icons.description,
                          maxLines: 3,
                        ),

                        SizedBox(height: 14),
                        LabelText("Gambar"),
                        GestureDetector(
                          onTap: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              imageFile = File(picked.path);
                              imgCtrl.text = picked.name;
                              setState(() {});
                            }
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: imgCtrl,
                              decoration: InputDecoration(
                                hintText: "Pilih gambar",
                                prefixIcon: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xff1d63ff),
                                ),
                                filled: true,
                                fillColor: const Color(0xfff6f8fc),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<bool>(
                                valueListenable: isSubmitting,
                                builder: (_, loading, __) {
                                  return OutlinedButton(
                                    onPressed: loading
                                        ? null
                                        : () => Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade600,
                                      side: BorderSide(
                                        color: Colors.red.shade400,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      "Batal",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ValueListenableBuilder<bool>(
                                valueListenable: isSubmitting,
                                builder: (context, loading, _) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff1d63ff),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xff1d63ff,
                                      ).withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () async {
                                            if (isSubmitting.value) return;

                                            if (!isFieldFilled()) {
                                              await showDialog(
                                                context: context,
                                                builder: (_) => const AlertDialog(
                                                  content: Text(
                                                    "Harap lengkapi semua field terlebih dahulu",
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            isSubmitting.value = true;

                                            try {
                                              final submitSiteIds =
                                                  userRole == "superadmin"
                                                  ? (isForAllSites
                                                        ? siteList
                                                              .map(
                                                                (e) =>
                                                                    e["id"]
                                                                        as int,
                                                              )
                                                              .toList()
                                                        : selectedSiteIds)
                                                  : [userSiteId];

                                              DailyPlan? result = plan == null
                                                  ? await HSESDailyPlanService.submit(
                                                      judul: titleCtrl.text,
                                                      subJudul: subCtrl.text,
                                                      deskripsi: descCtrl.text,
                                                      gambar: imageFile,
                                                      siteIds: submitSiteIds,
                                                      isForAllSites:
                                                          isForAllSites,
                                                    )
                                                  : await HSESDailyPlanService.update(
                                                      id: plan.id,
                                                      judul: titleCtrl.text,
                                                      subJudul: subCtrl.text,
                                                      deskripsi: descCtrl.text,
                                                      gambar: imageFile,
                                                      siteIds: submitSiteIds,
                                                      isForAllSites:
                                                          isForAllSites,
                                                    );

                                              if (!context.mounted) return;

                                              if (result != null) {
                                                Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).pop(result);
                                              }
                                            } finally {
                                              isSubmitting.value = false;
                                            }
                                          },
                                    child: loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "Simpan",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  );
                                },
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
          );
        },
      );
    },
  );
}
