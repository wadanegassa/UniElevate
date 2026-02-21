enum QuestionType { mcq, theory }

class Question {
  final String id;
  final String examId;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final String? correctAnswer;
  final List<String>? keywords;

  Question({
    required this.id,
    required this.examId,
    required this.text,
    required this.type,
    this.options,
    this.correctAnswer,
    this.keywords,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      examId: json['exam_id'],
      text: json['text'],
      type: json['type'] == 'MCQ' ? QuestionType.mcq : QuestionType.theory,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      correctAnswer: json['correct_answer'],
      keywords: json['keywords'] != null ? List<String>.from(json['keywords']) : null,
    );
  }
}
