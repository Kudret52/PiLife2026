import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

const List<String> kEventTypes = ["Etkinlik", "Hatırlatma", "Doğum Günü"];

String eventTypeToApi(String label) {
  switch (label) {
    case "Hatırlatma":
      return "reminder";
    case "Doğum Günü":
      return "birthday";
    default:
      return "event";
  }
}

String eventTypeFromApi(String value) {
  switch (value) {
    case "reminder":
      return "Hatırlatma";
    case "birthday":
      return "Doğum Günü";
    default:
      return "Etkinlik";
  }
}

IconData eventTypeIcon(String value) {
  switch (value) {
    case "reminder":
      return Icons.alarm_rounded;
    case "birthday":
      return Icons.cake_rounded;
    default:
      return Icons.event_rounded;
  }
}

Color eventTypeColor(String value) {
  switch (value) {
    case "reminder":
      return Colors.orange;
    case "birthday":
      return Colors.pink;
    default:
      return const Color(0xFF5B2D90);
  }
}

const List<String> kWeekdayLabels = [
  "Pzt",
  "Sal",
  "Çar",
  "Per",
  "Cum",
  "Cmt",
  "Paz",
];

const List<String> kMonthNames = [
  "Ocak",
  "Şubat",
  "Mart",
  "Nisan",
  "Mayıs",
  "Haziran",
  "Temmuz",
  "Ağustos",
  "Eylül",
  "Ekim",
  "Kasım",
  "Aralık",
];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color primaryColor = Color(0xFF5B2D90);

  bool loading = true;
  List events = [];

  DateTime focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_calendar_events.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        loading = false;
        if (data["success"] == true) {
          events = data["events"] ?? [];
        }
      });
    } catch (e) {
      debugPrint("loadEvents hata: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createEvent({
    required String title,
    required DateTime date,
    TimeOfDay? time,
    required String type,
    required String notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/create_calendar_event.php",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "title": title,
          "event_date":
              "${date.year.toString().padLeft(4, '0')}-"
              "${date.month.toString().padLeft(2, '0')}-"
              "${date.day.toString().padLeft(2, '0')}",
          "event_time": time != null
              ? "${time.hour.toString().padLeft(2, '0')}:"
                    "${time.minute.toString().padLeft(2, '0')}:00"
              : "",
          "type": eventTypeToApi(type),
          "notes": notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await loadEvents();
      }
    } catch (e) {
      debugPrint("createEvent hata: $e");
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/delete_calendar_event.php",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "user_id": UserService.id}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await loadEvents();
      }
    } catch (e) {
      debugPrint("deleteEvent hata: $e");
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List eventsOn(DateTime day) {
    return events.where((e) {
      try {
        final d = DateTime.parse(e["event_date"].toString());
        return isSameDay(d, day);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  void changeMonth(int delta) {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + delta);
    });
  }

  void showAddDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime chosenDate = selectedDay;
    TimeOfDay? chosenTime;
    String chosenType = kEventTypes.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Yeni Etkinlik"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Başlık"),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: chosenType,
                      decoration: const InputDecoration(labelText: "Tür"),
                      items: kEventTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => chosenType = value);
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        "${chosenDate.day} ${kMonthNames[chosenDate.month - 1]} ${chosenDate.year}",
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: chosenDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => chosenDate = picked);
                        }
                      },
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        chosenTime != null
                            ? chosenTime!.format(dialogContext)
                            : "Saat seç (opsiyonel)",
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => chosenTime = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Not (opsiyonel)",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Başlık girin.")),
                      );
                      return;
                    }

                    await createEvent(
                      title: titleController.text.trim(),
                      date: chosenDate,
                      time: chosenTime,
                      type: chosenType,
                      notes: notesController.text.trim(),
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;

    // Pazartesi = 1 ... Pazar = 7
    final leadingEmptyCells = firstDayOfMonth.weekday - 1;

    final dayEvents = eventsOn(selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text("Takvim"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadEvents,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => changeMonth(-1),
                      ),
                      Text(
                        "${kMonthNames[focusedMonth.month - 1]} ${focusedMonth.year}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => changeMonth(1),
                      ),
                    ],
                  ),

                  Row(
                    children: kWeekdayLabels
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 6),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                    itemCount: leadingEmptyCells + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < leadingEmptyCells) {
                        return const SizedBox();
                      }

                      final day = index - leadingEmptyCells + 1;
                      final date = DateTime(
                        focusedMonth.year,
                        focusedMonth.month,
                        day,
                      );

                      final isSelected = isSameDay(date, selectedDay);
                      final isToday = isSameDay(date, DateTime.now());
                      final hasEvents = eventsOn(date).isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedDay = date);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isToday
                                      ? primaryColor.withValues(alpha: 0.12)
                                      : null),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$day",
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (hasEvents)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  Text(
                    "${selectedDay.day} ${kMonthNames[selectedDay.month - 1]} ${selectedDay.year}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (dayEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Bu gün için etkinlik yok.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...dayEvents.map((e) {
                      final type = e["type"].toString();
                      final time = (e["event_time"] ?? "").toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: eventTypeColor(
                              type,
                            ).withValues(alpha: 0.15),
                            child: Icon(
                              eventTypeIcon(type),
                              color: eventTypeColor(type),
                            ),
                          ),
                          title: Text(
                            e["title"]?.toString() ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            [
                              eventTypeFromApi(type),
                              if (time.isNotEmpty) time.substring(0, 5),
                              if ((e["notes"] ?? "").toString().isNotEmpty)
                                e["notes"].toString(),
                            ].join(" • "),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              deleteEvent(int.parse(e["id"].toString()));
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
