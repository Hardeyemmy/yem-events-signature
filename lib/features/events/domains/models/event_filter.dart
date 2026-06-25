class EventFilter {
  final String? keyword;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;

  const EventFilter({
    this.keyword,
    this.location,
    this.startDate,
    this.endDate,
  });

  bool get isEmpty =>
      keyword == null &&
      location == null &&
      startDate == null &&
      endDate == null;

  EventFilter copyWith({
    String? keyword,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return EventFilter(
      keyword: keyword ?? this.keyword,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
