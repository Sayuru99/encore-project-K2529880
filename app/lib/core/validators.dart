// Form validators. Each returns an error message, or null when the value is fine.

String? requiredText(String? v, {int max = 100, String field = 'This field'}) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return '$field is required';
  if (t.length > max) return '$field must be $max characters or less';
  return null;
}

String? email(String? v) =>
    RegExp(r'^\S+@\S+\.\S+$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid email';

String? password(String? v) => (v ?? '').length < 6 ? 'Use at least 6 characters' : null;

String? price(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return null; // empty means free
  final n = double.tryParse(t);
  if (n == null || n < 0) return 'Enter a price of 0 or more';
  if (n > 100000) return 'That price looks too high';
  return null;
}

/// You cannot have attended something that has not happened yet.
String? attendedDate(String status, DateTime date) =>
    status == 'attended' && date.isAfter(DateTime.now()) ? 'An event in the future cannot be marked as attended' : null;
