import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/gradient_elevated_button.dart';

class BookingEventOption {
  final String id;
  final String name;
  final String type;
  final DateTime date;
  final String location;

  BookingEventOption({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.location,
  });
}

class BookingPackageOption {
  final String id;
  final String name;
  final double amount;
  final String description;

  BookingPackageOption({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
  });
}

class BookingSelection {
  final BookingEventOption event;
  final BookingPackageOption package;

  BookingSelection({required this.event, required this.package});
}

class EventSelectionBottomSheet extends StatefulWidget {
  final String providerName;
  final String clientName;
  final List<BookingEventOption> eventOptions;
  final List<BookingPackageOption> packageOptions;
  final bool isFixedEvent;

  const EventSelectionBottomSheet({
    super.key,
    required this.providerName,
    required this.clientName,
    required this.eventOptions,
    required this.packageOptions,
    this.isFixedEvent = false,
  });

  @override
  State<EventSelectionBottomSheet> createState() =>
      _EventSelectionBottomSheetState();
}

class _EventSelectionBottomSheetState extends State<EventSelectionBottomSheet> {
  BookingEventOption? _selectedEvent;
  BookingPackageOption? _selectedPackage;

  @override
  void initState() {
    super.initState();
    if (widget.eventOptions.isNotEmpty) {
      _selectedEvent = widget.eventOptions.first;
    }
    if (widget.packageOptions.isNotEmpty) {
      _selectedPackage = widget.packageOptions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(25.w, 30.h, 25.w, 40.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book ${widget.providerName}',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Choose the event and package so both you and the provider see the same booking details.',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            SizedBox(height: 30.h),

            _buildLabel('Client'),
            _buildReadOnlyField(widget.clientName),
            SizedBox(height: 25.h),

            _buildLabel('Event'),
            _buildEventDropdown(),
            if (_selectedEvent != null) ...[
              SizedBox(height: 20.h),
              _buildDetailItem(
                Icons.location_on_outlined,
                'Location',
                _selectedEvent!.location,
              ),
              SizedBox(height: 15.h),
              _buildDetailItem(
                Icons.calendar_today_outlined,
                'Event Type',
                _selectedEvent!.type,
              ),
            ],
            SizedBox(height: 25.h),

            _buildLabel('Package'),
            _buildPackageDropdown(),
            if (_selectedPackage != null) ...[
              SizedBox(height: 20.h),
              _buildDetailItem(
                Icons.payments_outlined,
                'Amount',
                'Rs. ${_selectedPackage!.amount.toStringAsFixed(2)}',
              ),
            ],
            SizedBox(height: 40.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: GradientElevatedButton(
                    onPressed: (_selectedEvent != null && _selectedPackage != null)
                        ? () {
                            Navigator.pop(
                              context,
                              BookingSelection(
                                event: _selectedEvent!,
                                package: _selectedPackage!,
                              ),
                            );
                          }
                        : null,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    borderRadius: 12.r,
                    child: Text(
                      'Send Request',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A1C1E),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1C1E),
        ),
      ),
    );
  }

  Widget _buildEventDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BookingEventOption>(
          value: _selectedEvent,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          items: widget.eventOptions.map((event) {
            final dateStr = DateFormat('d MMM yyyy').format(event.date);
            return DropdownMenuItem(
              value: event,
              child: Text(
                '${event.name} • $dateStr',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedEvent = val),
        ),
      ),
    );
  }

  Widget _buildPackageDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BookingPackageOption>(
          value: _selectedPackage,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          items: widget.packageOptions.map((pkg) {
            return DropdownMenuItem(
              value: pkg,
              child: Text(
                '${pkg.name} • Rs. ${pkg.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedPackage = val),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: const Color(0xFF008069).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: const Color(0xFF008069), size: 20.sp),
        ),
        SizedBox(width: 15.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
