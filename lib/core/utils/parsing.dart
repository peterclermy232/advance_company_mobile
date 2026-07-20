/// Backend DecimalFields (money, rates) are serialized as JSON strings
/// (e.g. `"20000.00"`), not numbers. This parses either shape safely.
double parseDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
