class Answer {
  final String studentId;
  final String examId;
  final String questionId;
  final String transcript;
  final bool isCorrect;
  final double score;
  final String feedback;
  final DateTime timestamp;

  Answer({
    required this.studentId,
    required this.examId,
    required this.questionId,
    required this.transcript,
    required this.isCorrect,
    required this.score,
    required this.feedback,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'exam_id': examId,
      'question_id': questionId,
      'transcript': transcript,
      'is_correct': isCorrect,
      'score': score,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
