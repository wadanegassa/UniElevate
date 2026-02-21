import 'question_model.dart';

class Exam {
  final String id;
  final String title;
  final int duration;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? accessCode;
  final List<Question> questions;

  Exam({
    required this.id,
    required this.title,
    required this.duration,
    this.startTime,
    this.endTime,
    this.accessCode,
    this.questions = const [],
  });

  factory Exam.fromJson(Map<String, dynamic> json, {List<Question> questions = const []}) {
    return Exam(
      id: json['id'],
      title: json['title'],
      duration: json['duration'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      accessCode: json['access_code'],
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'access_code': accessCode,
    };
  }
}
