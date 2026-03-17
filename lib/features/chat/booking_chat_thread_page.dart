import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/colors.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';

class BookingChatThreadPage extends StatefulWidget {
  const BookingChatThreadPage({
    super.key,
    required this.bookingId,
    this.initialThreadData,
  });

  final String bookingId;
  final Map<String, dynamic>? initialThreadData;

  @override
  State<BookingChatThreadPage> createState() => _BookingChatThreadPageState();
}

class _BookingChatThreadPageState extends State<BookingChatThreadPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  // True once thread document is created in Firestore. The messages stream
  // must NOT start before this, otherwise Firestore denies the read because
  // the parent booking_chats doc doesn't exist yet.
  bool _threadReady = false;

  @override
  void initState() {
    super.initState();
    _initThread();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initThread() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        await _chatService.ensureThreadExistsForBooking(
          bookingId: widget.bookingId,
          bookingData: widget.initialThreadData,
        );
        await _chatService.markThreadRead(
          bookingId: widget.bookingId,
          currentUserId: user.uid,
        );
      }
    } catch (e) {
      debugPrint('Error in _initThread: $e');
    } finally {
      if (mounted) setState(() => _threadReady = true);
    }
  }

  Future<void> _sendMessage(Map<String, dynamic> threadData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final senderName = firstNonEmpty([
      user.displayName,
      threadData['userId'] == user.uid
          ? threadData['clientName']
          : threadData['providerName'],
      user.email?.split('@').first,
    ], fallback: 'You');

    final recipientId = threadData['userId'] == user.uid
        ? (threadData['providerId']?.toString() ?? '')
        : (threadData['userId']?.toString() ?? '');

    if (recipientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot identify recipient. Chat might not be initialized.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(
        bookingId: widget.bookingId,
        senderId: user.uid,
        recipientId: recipientId,
        senderName: senderName,
        text: text,
        bookingData: threadData,
      );
      _messageController.clear();
      _scrollToBottom();
      await _chatService.markThreadRead(
        bookingId: widget.bookingId,
        currentUserId: user.uid,
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Unable to send message: $e';
      if (e is FirebaseException && e.code == 'permission-denied') {
        errorMessage =
        'Unable to send message: The caller does not have permission to execute the specified operation.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: user == null
              ? Center(
            child: Text(
              'Please login to use chat.',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _chatService.watchThread(widget.bookingId),
            builder: (context, snapshot) {
              final threadData =
                  snapshot.data?.data() ?? widget.initialThreadData;

              if (snapshot.hasError) {
                String errorMessage = 'Error loading thread: ${snapshot.error}';
                final isPermissionDenied =
                    snapshot.error is FirebaseException &&
                        (snapshot.error as FirebaseException).code ==
                            'permission-denied';

                // Keep chat usable when parent thread get is denied but we already
                // have valid thread metadata from the previous screen.
                if (isPermissionDenied && threadData != null) {
                  debugPrint(
                    'Thread stream denied for ${widget.bookingId}, using initialThreadData fallback.',
                  );
                } else {
                  if (isPermissionDenied) {
                    errorMessage =
                    'Error loading messages: The caller does not have permission to execute the specified operation.';
                  }
                  return _buildErrorState(errorMessage);
                }
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData &&
                  widget.initialThreadData == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (threadData == null) {
                return _buildMissingThreadState(context);
              }

              return Column(
                children: [
                  _buildHeader(context, user.uid, threadData),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(35.r),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildBookingSummary(threadData),
                          Expanded(
                            child: !_threadReady
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen,
                                    ),
                                  )
                                : StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>>(
                              stream: _chatService.watchMessages(
                                widget.bookingId,
                              ),
                              builder: (context, messageSnapshot) {
                                if (messageSnapshot.hasError) {
                                  String errorMessage =
                                      'Error loading messages: ${messageSnapshot.error}';
                                  if (messageSnapshot.error
                                  is FirebaseException &&
                                      (messageSnapshot.error
                                      as FirebaseException)
                                          .code ==
                                          'permission-denied') {
                                    errorMessage =
                                    'Error loading messages: The caller does not have permission to execute the specified operation.';
                                  }
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.r),
                                      child: Text(
                                        errorMessage,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (messageSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                    !messageSnapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen,
                                    ),
                                  );
                                }

                                final messages = messageSnapshot
                                    .data?.docs ??
                                    <QueryDocumentSnapshot<
                                        Map<String, dynamic>>>[];

                                if (messages.isNotEmpty) {
                                  final lastMessage =
                                  messages.first.data();
                                  if (lastMessage['senderId'] !=
                                      user.uid) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      _chatService.markThreadRead(
                                        bookingId: widget.bookingId,
                                        currentUserId: user.uid,
                                      );
                                    });
                                  }
                                  _scrollToBottom();
                                }

                                if (messages.isEmpty) {
                                  return _buildEmptyMessages();
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: EdgeInsets.fromLTRB(
                                    18.w,
                                    12.h,
                                    18.w,
                                    18.h,
                                  ),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final data = messages[index].data();
                                    final isMe =
                                        data['senderId'] == user.uid;
                                    return _MessageBubble(
                                      isMe: isMe,
                                      senderName: data['senderName']
                                          ?.toString() ??
                                          'Unknown',
                                      message:
                                      data['text']?.toString() ?? '',
                                      timestamp: bookingChatDateFrom(
                                        data['createdAt'],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          _buildComposer(threadData),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      String currentUserId,
      Map<String, dynamic> threadData,
      ) {
    final counterpartName = bookingChatCounterpartNameFrom(
      threadData,
      currentUserId,
    );
    final eventName =
    threadData['eventName']?.toString().trim().isNotEmpty == true
        ? threadData['eventName'].toString().trim()
        : 'Booking Chat';

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counterpartName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  eventName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(Map<String, dynamic> threadData) {
    final eventDate = bookingChatDateFrom(threadData['eventDate']);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 6.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [AppColors.cardShadow(opacity: 0.05)],
      ),
      child: Column(
        children: [
          _SummaryTile(
            icon: Icons.inventory_2_outlined,
            label: 'Package',
            value:
            threadData['selectedPackage']?.toString() ?? 'Custom Package',
            color: AppColors.primaryGreen,
          ),
          _SummaryTile(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value:
            threadData['location']?.toString() ?? 'Location not specified',
            color: Colors.orange,
          ),
          _SummaryTile(
            icon: Icons.calendar_today,
            label: 'Event Date',
            value: eventDate == null ? 'Date not set' : _formatDate(eventDate),
            color: AppColors.primaryBlue,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 72.sp,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              'Start the booking conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Share updates, ask questions, and coordinate details for this booking here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(Map<String, dynamic> threadData) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(threadData),
                decoration: InputDecoration(
                  hintText: 'Type your message',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            SizedBox(
              width: 52.w,
              height: 52.w,
              child: ElevatedButton(
                onPressed: _isSending ? null : () => _sendMessage(threadData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _isSending
                    ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Icon(Icons.send_rounded, size: 22.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingThreadState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 72.sp, color: Colors.white70),
            SizedBox(height: 16.h),
            Text(
              'This chat isn’t ready yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Go back and reopen the booking to try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 20.h),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isMe,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  final bool isMe;
  final String senderName;
  final String message;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.primaryGreen : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.textDark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.r),
        constraints: BoxConstraints(maxWidth: 0.78.sw),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(isMe ? 18.r : 6.r),
            bottomRight: Radius.circular(isMe ? 6.r : 18.r),
          ),
          boxShadow: [AppColors.cardShadow(opacity: isMe ? 0.05 : 0.08)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(timestamp),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isMe
                      ? Colors.white.withOpacity(0.85)
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return 'Sending...';
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}