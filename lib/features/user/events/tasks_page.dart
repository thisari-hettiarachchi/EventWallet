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
  final _taskController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

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
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(20.r),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildTaskCard(doc.id, data);
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
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: AppColors.primaryBlue,
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
              'Tasks',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80.sp,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Click the + button to add one.',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String docId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Unnamed Task';
    final isDone = data['isDone'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [AppColors.cardShadow()],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        leading: Transform.scale(
          scale: 1.2.r,
          child: Checkbox(
            value: isDone,
            onChanged: (value) {
              if (value == null) return;
              FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .collection('tasks')
                  .doc(docId)
                  .update({'isDone': value});
            },
            activeColor: AppColors.primaryBlue,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red, size: 24.sp),
          onPressed: () {
            FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId)
                .collection('tasks')
                .doc(docId)
                .delete();
          },
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final parentContext = context;
    _taskController.clear();
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add a new task',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              content: TextField(
                controller: _taskController,
                autofocus: true,
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(
                  hintText: 'Task title',
                  hintStyle: TextStyle(fontSize: 14.sp),
                  errorText: _taskController.text.isEmpty && _isAdding ? 'Task cannot be empty' : null,
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _taskController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                ),
                GradientElevatedButton(
                  onPressed: _isAdding
                      ? null
                      : () async {
                          if (_taskController.text.trim().isNotEmpty) {
                            setDialogState(() => _isAdding = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(widget.eventId)
                                  .collection('tasks')
                                  .add({
                                'title': _taskController.text.trim(),
                                'isDone': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              _taskController.clear();
                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(content: Text('Failed to add task: $e')),
                              );
                            } finally {
                              if (mounted) setDialogState(() => _isAdding = false);
                            }
                          }
                        },
                  borderRadius: 12.r,
                  child: _isAdding
                      ? SizedBox(
                          height: 18.sp,
                          width: 18.sp,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Add',
                          style: TextStyle(fontSize: 14.sp, color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
