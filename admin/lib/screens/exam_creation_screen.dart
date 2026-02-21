import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../providers/exam_manager_provider.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

class ExamCreationScreen extends StatefulWidget {
  const ExamCreationScreen({super.key});

  @override
  State<ExamCreationScreen> createState() => _ExamCreationScreenState();
}

class _ExamCreationScreenState extends State<ExamCreationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<Question> _questions = [];

  void _addQuestion(QuestionType type) {
    setState(() {
      _questions.add(Question(
        id: '',
        examId: '',
        text: '',
        type: type,
        options: type == QuestionType.mcq ? ['', '', '', ''] : null,
        correctAnswer: '',
        keywords: type == QuestionType.theory ? [] : null,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<ExamManagerProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Exam",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // Exam Details
            _buildCard(
              title: "Exam Details",
              children: [
                FormBuilderTextField(
                  name: 'title',
                  decoration: _inputDecoration("Exam Title"),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'duration',
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Duration (Minutes)"),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.numeric(),
                  ]),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'access_code',
                  decoration: _inputDecoration("Student Access Command (Password)"),
                  validator: FormBuilderValidators.required(),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              "Questions",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Question List
            ..._questions.asMap().entries.map((entry) {
              int idx = entry.key;
              Question q = entry.value;
              return _buildQuestionCard(idx, q);
            }),
            
            const SizedBox(height: 24),
            Row(
              children: [
                _buildActionButton("Add MCQ", Icons.list, () => _addQuestion(QuestionType.mcq)),
                const SizedBox(width: 16),
                _buildActionButton("Add Theory", Icons.description, () => _addQuestion(QuestionType.theory)),
              ],
            ),
            
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: manager.isLoading ? null : () async {
                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  final values = _formKey.currentState!.value;
                  final exam = Exam(
                    id: '',
                    title: values['title'],
                    duration: int.parse(values['duration']),
                    accessCode: values['access_code'],
                  );
                  
                  // In a real app, you'd extract question values from the form too
                  final messenger = ScaffoldMessenger.of(context);
                  await manager.createExamWithQuestions(exam, _questions);
                  
                  if (!mounted) return;
                  
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Exam created successfully")),
                  );
                  setState(() {
                    _questions.clear();
                    _formKey.currentState?.reset();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("DEPLOY EXAM", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Question q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Question ${index + 1} (${q.type == QuestionType.mcq ? 'MCQ' : 'Theory'})", 
                style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => _questions.removeAt(index)), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => _questions[index] = _updateQuestionText(q, val),
            decoration: _inputDecoration("Question Text"),
            style: const TextStyle(color: Colors.white),
          ),
          if (q.type == QuestionType.mcq) ...[
            const SizedBox(height: 16),
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                onChanged: (val) => q.options![i] = val,
                decoration: _inputDecoration("Option ${i + 1}"),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            )),
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => _questions[index] = _updateQuestionCorrectAnswer(q, val),
              decoration: _inputDecoration("Correct Answer"),
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ] else ...[
            const SizedBox(height: 16),
            TextField(
              onChanged: (val) => _questions[index] = _updateQuestionKeywords(q, val),
              decoration: _inputDecoration("Keywords (comma separated)"),
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.indigoAccent)),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Question _updateQuestionText(Question q, String text) => Question(id: q.id, examId: q.examId, text: text, type: q.type, options: q.options, correctAnswer: q.correctAnswer, keywords: q.keywords);
  Question _updateQuestionCorrectAnswer(Question q, String val) => Question(id: q.id, examId: q.examId, text: q.text, type: q.type, options: q.options, correctAnswer: val, keywords: q.keywords);
  Question _updateQuestionKeywords(Question q, String val) => Question(id: q.id, examId: q.examId, text: q.text, type: q.type, options: q.options, correctAnswer: q.correctAnswer, keywords: val.split(',').map((e) => e.trim()).toList());
}
