import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_item.dart';
import '../state/app_repository.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/empty_state.dart';

class ScheduleItemsScreen extends StatefulWidget {
  const ScheduleItemsScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  State<ScheduleItemsScreen> createState() => _ScheduleItemsScreenState();
}

class _ScheduleItemsScreenState extends State<ScheduleItemsScreen> {
  List<ScheduleItem> _items = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AppRepository>();
    final items = widget.subjectId != null
        ? await repo.listScheduleItemsForSubject(widget.subjectId!)
        : await repo.listAllScheduleItems();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  List<ScheduleItem> get _filtered {
    if (_filter == 'all') return _items;
    return _items.where((i) => i.type.name == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectId != null ? 'Subject items' : 'All items'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _chip('all', 'All'),
                _chip('quiz', 'Quizzes'),
                _chip('reminder', 'Reminders'),
                _chip('activity', 'Activities'),
                _chip('note', 'Notes'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Nothing here yet',
                        message: 'Add quizzes, reminders, or notes from a class block.',
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              await context.read<AppRepository>().deleteScheduleItem(item.id);
                              _load();
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: item.isCompleted,
                                onChanged: (v) async {
                                  await context.read<AppRepository>().saveScheduleItem(
                                        ScheduleItem(
                                          id: item.id,
                                          subjectId: item.subjectId,
                                          type: item.type,
                                          title: item.title,
                                          description: item.description,
                                          dueDate: item.dueDate,
                                          dueTime: item.dueTime,
                                          isCompleted: v ?? false,
                                          priority: item.priority,
                                          colorTag: item.colorTag,
                                          attachmentPaths: item.attachmentPaths,
                                          repeatRule: item.repeatRule,
                                          createdAt: item.createdAt,
                                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                                        ),
                                      );
                                  _load();
                                },
                              ),
                              title: Text(item.title),
                              subtitle: Text('${item.type.name} · ${item.subjectId}'),
                              onTap: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddItemSheet(
                                  subjectId: item.subjectId,
                                  type: item.type,
                                  existing: item,
                                  onSaved: _load,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final sel = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
