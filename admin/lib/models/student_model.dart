class Student {
  final String id;
  final String name;
  final String email;
  final List<String> assignedExamIds;
  final String? deviceId;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.assignedExamIds,
    this.deviceId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      assignedExamIds: json['assigned_exam_ids'] != null 
          ? List<String>.from(json['assigned_exam_ids']) 
          : [],
      deviceId: json['device_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'assigned_exam_ids': assignedExamIds,
      'device_id': deviceId,
    };
  }
}
