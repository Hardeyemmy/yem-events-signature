import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/event_provider.dart';

class EventSearchBar extends ConsumerStatefulWidget {
  const EventSearchBar({super.key});

  @override
  ConsumerState<EventSearchBar> createState() => _EventSearchBarState();
}

class _EventSearchBarState extends ConsumerState<EventSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearAll() {
    _controller.clear();
    ref.read(eventFilterControllerProvider.notifier).clearFilters();
  }

  Future<void> _pickDateRange() async {
    final filter = ref.read(eventFilterControllerProvider);
    final now = DateTime.now();

    final start = await showDatePicker(
      context: context,
      initialDate: filter.startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select start date',
    );
    if (start == null) return;
    if (!mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: filter.endDate ?? start,
      firstDate: start,
      lastDate: DateTime(2030),
      helpText: 'Select end date',
    );
    if (end == null) return;

    ref.read(eventFilterControllerProvider.notifier).setDateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(eventFilterControllerProvider);
    final hasDateFilter = filter.startDate != null || filter.endDate != null;
    final hasKeyword = filter.keyword?.isNotEmpty == true;
    final hasAnyFilter = hasDateFilter || hasKeyword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Single search field ──────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              ref
                  .read(eventFilterControllerProvider.notifier)
                  .setKeyword(value);
            },
            decoration: InputDecoration(
              hintText: 'Search by keyword or location...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.deepPurple,
                size: 22,
              ),
              // Date filter chip — shown inside field when active
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date picker icon button
                  IconButton(
                    tooltip: 'Filter by date',
                    icon: Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: hasDateFilter
                          ? Colors.deepPurple
                          : Colors.grey[400],
                    ),
                    onPressed: _pickDateRange,
                  ),
                  // Clear button
                  if (hasAnyFilter)
                    IconButton(
                      tooltip: 'Clear filters',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.red.shade300,
                      ),
                      onPressed: _clearAll,
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // ── Active date filter chip ──────────────────────
        if (hasDateFilter) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _buildDateLabel(filter),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => ref
                          .read(eventFilterControllerProvider.notifier)
                          .setDateRange(null, null),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _buildDateLabel(dynamic filter) {
    final fmt = DateFormat.yMd();
    if (filter.startDate != null && filter.endDate != null) {
      return '${fmt.format(filter.startDate!)} → ${fmt.format(filter.endDate!)}';
    } else if (filter.startDate != null) {
      return 'From ${fmt.format(filter.startDate!)}';
    } else if (filter.endDate != null) {
      return 'Until ${fmt.format(filter.endDate!)}';
    }
    return '';
  }
}
