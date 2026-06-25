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
      (keyword == null || keyword!.isEmpty) &&
      (location == null || location!.isEmpty) &&
      startDate == null &&
      endDate == null;

  // ✅ Fixed: use sentinel to allow setting fields back to null
  EventFilter copyWith({
    Object? keyword = _sentinel,
    Object? location = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
  }) {
    return EventFilter(
      keyword: keyword == _sentinel ? this.keyword : keyword as String?,
      location: location == _sentinel ? this.location : location as String?,
      startDate: startDate == _sentinel
          ? this.startDate
          : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
    );
  }
}

// Sentinel value to distinguish null from "not provided"
const Object _sentinel = Object();
