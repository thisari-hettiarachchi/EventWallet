import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gradient_elevated_button.dart';

class TasksPage extends StatefulWidget {
  final String eventId;
  const TasksPage({super.key, required this.eventId});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 20.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35.r),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId)
                        .collection('tasks')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data!.docs;

                      if (tasks.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(20.r),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final data = task.data() as Map<String, dynamic>;
                          return _buildTaskCard(task.id, data);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.primaryGreen,
        child: Icon(Icons.add, color: Colors.white, size: 24.sp),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'Event Tasks',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String taskId, Map<String, dynamic> data) {
    final bool isDone = data['isDone'] ?? false;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: ListTile(
        leading: Transform.scale(
          scale: 1.2.r,
          child: Checkbox(
            value: isDone,
            activeColor: AppColors.primaryGreen,
            onChanged: (value) {
              FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .collection('tasks')
                  .doc(taskId)
                  .update({'isDone': value});
            },
          ),
        ),
        title: Text(
          data['title'] ?? '',
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red, size: 24.sp),
          onPressed: () {
            FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId)
                .collection('tasks')
                .doc(taskId)
                .delete();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 80.sp,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Task',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _taskController,
          style: TextStyle(fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'Task description',
            hintStyle: TextStyle(fontSize: 14.sp),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          GradientElevatedButton(
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('events')
                    .doc(widget.eventId)
                    .collection('tasks')
                    .add({
                      'title': _taskController.text.trim(),
                      'isDone': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                _taskController.clear();
                Navigator.pop(context);
              }
            },
            borderRadius: 12.r,
            child: Text(
              'Add',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
