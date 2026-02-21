class Answer {
  final String studentId;
  final String questionId;
  final String transcript;
  final bool isCorrect;
  final double score;
  final String feedback;
  final DateTime timestamp;

  Answer({
    required this.studentId,
    required this.questionId,
    required this.transcript,
    required this.isCorrect,
    required this.score,
    required this.feedback,
    required this.timestamp,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      studentId: json['student_id'],
      questionId: json['question_id'],
      transcript: json['transcript'],
      isCorrect: json['is_correct'],
      score: (json['score'] as num).toDouble(),
      feedback: json['feedback'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'question_id': questionId,
      'transcript': transcript,
      'is_correct': isCorrect,
      'score': score,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
