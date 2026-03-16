import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/colors.dart';

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

  const EventSelectionBottomSheet({
    super.key,
    required this.providerName,
    required this.clientName,
    required this.eventOptions,
    required this.packageOptions,
  });

  @override
  State<EventSelectionBottomSheet> createState() => _EventSelectionBottomSheetState();
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Select Event & Package',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Which event is this booking for?',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10.h),
          _buildEventDropdown(),
          SizedBox(height: 20.h),
          Text(
            'Select a Package',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10.h),
          _buildPackageDropdown(),
          SizedBox(height: 30.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                'Confirm Booking Request',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BookingEventOption>(
          value: _selectedEvent,
          isExpanded: true,
          items: widget.eventOptions.map((event) {
            return DropdownMenuItem(
              value: event,
              child: Text(event.name, style: TextStyle(fontSize: 15.sp)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedEvent = val),
        ),
      ),
    );
  }

  Widget _buildPackageDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BookingPackageOption>(
          value: _selectedPackage,
          isExpanded: true,
          items: widget.packageOptions.map((pkg) {
            return DropdownMenuItem(
              value: pkg,
              child: Text('${pkg.name} - \$${pkg.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 15.sp)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedPackage = val),
        ),
      ),
    );
  }
}
