import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/event_provider.dart';

class EventSearchBar extends ConsumerWidget {
  const EventSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(eventFilterProvider);

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search by Keyword',
            prefixIcon: Icon(Icons.search),
            prefixIconColor: Colors.white24,
          ),
          onChanged: (value) => ref
              .read(eventFilterControllerProvider.notifier)
              .setKeyword(value),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: ' Filter by location',
            prefixIcon: Icon(Icons.location_on),
            prefixIconColor: Colors.white24,
          ),
          onChanged: (value) => ref
              .read(eventFilterControllerProvider.notifier)
              .setKeyword(value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filter.startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    ref
                        .read(eventFilterControllerProvider.notifier)
                        .setDateRange(date, filter.endDate);
                  }
                },
                label: Text(
                  filter.startDate == null
                      ? 'Start Date'
                      : DateFormat.yMd().format((filter.startDate!)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  filter.endDate == null
                      ? 'End Date'
                      : DateFormat.yMd().format(filter.endDate!),
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filter.endDate ?? DateTime.now(),
                    firstDate: filter.startDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    ref
                        .read(eventFilterControllerProvider.notifier)
                        .setDateRange(filter.startDate, date);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref
                  .read(eventFilterControllerProvider.notifier)
                  .clearFilters(),
            ),
          ],
        ),
      ],
    );
  }
}
