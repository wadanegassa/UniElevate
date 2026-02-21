import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import '../providers/monitor_provider.dart';
import 'package:intl/intl.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MonitorProvider>(context, listen: false).startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitorProvider = Provider.of<MonitorProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Live Monitoring",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Real-time student responses and AI grading feed",
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                    SizedBox(width: 8),
                    Text("LIVE FEED", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                cardColor: const Color(0xFF151515),
                dividerColor: Colors.white12,
              ),
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 1000,
                columns: const [
                  DataColumn2(label: Text('Time'), fixedWidth: 100),
                  DataColumn2(label: Text('Student ID'), fixedWidth: 150),
                  DataColumn2(label: Text('Transcript'), size: ColumnSize.L),
                  DataColumn2(label: Text('AI Grade'), fixedWidth: 100),
                  DataColumn2(label: Text('Score'), fixedWidth: 80),
                  DataColumn2(label: Text('Feedback'), size: ColumnSize.M),
                ],
                rows: monitorProvider.recentAnswers.map((answer) {
                  return DataRow(cells: [
                    DataCell(Text(DateFormat('HH:mm:ss').format(answer.timestamp), style: const TextStyle(color: Colors.white38))),
                    DataCell(Text(answer.studentId, style: const TextStyle(color: Colors.indigoAccent))),
                    DataCell(Text(answer.transcript, style: const TextStyle(color: Colors.white70))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: answer.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          answer.isCorrect ? "CORRECT" : "INCORRECT",
                          style: TextStyle(
                            color: answer.isCorrect ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(answer.score.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataCell(Text(answer.feedback, style: const TextStyle(color: Colors.white38, fontSize: 12))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
