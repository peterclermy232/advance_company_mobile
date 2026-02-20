import 'package:equatable/equatable.dart';

class ApplicationTypeModel extends Equatable {
  final String value;
  final String label;
  final String description;

  const ApplicationTypeModel({
    required this.value,
    required this.label,
    required this.description,
  });

  factory ApplicationTypeModel.fromJson(Map<String, dynamic> json) {
    return ApplicationTypeModel(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [value, label, description];
}

class StatusChoiceModel extends Equatable {
  final String value;
  final String label;

  const StatusChoiceModel({required this.value, required this.label});

  factory StatusChoiceModel.fromJson(Map<String, dynamic> json) {
    return StatusChoiceModel(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }

  static const Map<String, int> _colorMap = {
    'pending': 0xFFFF9800,
    'under_review': 0xFF2196F3,
    'approved': 0xFF4CAF50,
    'rejected': 0xFFF44336,
  };

  int get colorValue => _colorMap[value] ?? 0xFF9E9E9E;

  @override
  List<Object?> get props => [value, label];
}

/// Wraps GET /applications/choices/ response
class ApplicationChoicesModel extends Equatable {
  final List<ApplicationTypeModel> applicationTypes;
  final List<StatusChoiceModel> statusChoices;

  const ApplicationChoicesModel({
    required this.applicationTypes,
    required this.statusChoices,
  });

  factory ApplicationChoicesModel.fromJson(Map<String, dynamic> json) {
    return ApplicationChoicesModel(
      applicationTypes: (json['application_types'] as List<dynamic>)
          .map((e) => ApplicationTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusChoices: (json['status_choices'] as List<dynamic>)
          .map((e) => StatusChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [applicationTypes, statusChoices];
}