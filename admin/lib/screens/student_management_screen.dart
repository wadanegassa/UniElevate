import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_manager_provider.dart';
import '../models/student_model.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamManagerProvider>().loadInitialData();
    });
  }

  void _showAddStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text("Add New Student", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Full Name", labelStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Email Address", labelStyle: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Note: This only creates the PROFILE.
              // For a full demo, we assume the student uses the shared email/pass
              // or that Auth is handled separately.
              await context.read<ExamManagerProvider>().createStudent(
                _nameController.text,
                _emailController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              _nameController.clear();
              _emailController.clear();
            },
            child: const Text("Add Student"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<ExamManagerProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Student Management",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text("ADD STUDENT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: manager.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: manager.students.length,
                    itemBuilder: (context, index) {
                      final student = manager.students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.indigoAccent.withValues(alpha: 0.1),
                              child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: Colors.indigoAccent)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text(student.email, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: student.deviceId != null ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                student.deviceId != null ? "Device Bound" : "No Device",
                                style: TextStyle(
                                  color: student.deviceId != null ? Colors.greenAccent : Colors.amberAccent,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (student.deviceId != null)
                              IconButton(
                                tooltip: "Unbind Device",
                                icon: const Icon(Icons.device_reset, color: Colors.redAccent, size: 20),
                                onPressed: () => manager.unbindStudent(student.id),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
