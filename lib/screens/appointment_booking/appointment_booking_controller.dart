import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AppointmentBookingController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("doctors");
  final DatabaseReference patientRef = FirebaseDatabase.instance.ref("patients");

  // Doctor details
  late String doctorKey;
  late String doctorSpecialization;
  late String patientKey;
  Map<String, dynamic> doctorDetails = {};

  // Patient details
  Map<String, dynamic> patientDetails = {};

  // Date selection
  DateTime selectedDate = DateTime.now();
  List<DateTime> availableDates = [];

  // Time slots
  List<String> timeSlots = [
    '09:00 AM', '09:20 AM', '09:40 AM',
    '10:00 AM', '10:20 AM', '10:40 AM',
    '11:00 AM', '11:20 AM', '11:40 AM',
    '12:00 PM', '12:20 PM', '12:40 PM',
    '01:00 PM', '01:20 PM', '01:40 PM',
    '02:00 PM', '02:20 PM', '02:40 PM',
    '03:00 PM', '03:20 PM'
  ];

  List<String> bookedSlots = [];
  bool isLoading = true;
  String? selectedSlot;
  bool isProcessingPayment = false;

  @override
  void onInit() {
    super.onInit();
    Stripe.publishableKey = "YOUR_STRIPE_SECRET_KEY";
    _initializeData();
  }

  Future<void> _initializeData() async {
    final args = Get.arguments;
    doctorKey = args['doctorKey'];
    doctorSpecialization = args['doctorSpecialization'];
    patientKey = args['patientKey'];

    await _loadDoctorDetails();
    _generateAvailableDates();
    await loadBookedSlots();
    isLoading = false;
    update();
  }


  Future<void> _loadDoctorDetails() async {
    try {
      final snapshot = await _dbRef
          .child(doctorSpecialization)
          .child(doctorKey)
          .child('Personal Detail')
          .get();
      final patientSnapshot = await patientRef.child(patientKey).child("Personal Detail").get();


      if (snapshot.exists ) {
        doctorDetails = Map<String, dynamic>.from(snapshot.value as Map);
        patientDetails = Map<String, dynamic>.from(patientSnapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Error loading doctor details: $e');
    }
  }

  void _generateAvailableDates() {
    final today = DateTime.now();
    availableDates = List.generate(7, (index) =>
        DateTime(today.year, today.month, today.day + index));
  }

  Future<void> loadBookedSlots() async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      bookedSlots.clear();

      // Load all appointments for this doctor on selected date
      final doctorAppointments = await _dbRef
          .child(doctorSpecialization)
          .child(doctorKey)
          .child('Appointment')
          .orderByChild('date')
          .equalTo(formattedDate)
          .once();

      if (doctorAppointments.snapshot.exists) {
        final Map<dynamic, dynamic> appointments =
        doctorAppointments.snapshot.value as Map<dynamic, dynamic>;
        appointments.forEach((key, value) {
          if (value is Map) {
            bookedSlots.add(value['time'].toString());
          }
        });
      }

      update();
    } catch (e) {
      debugPrint('Error loading booked slots: $e');
      rethrow;
    }
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate = date;
    isLoading = true;
    update();
    await loadBookedSlots();
    isLoading = false;
    update();
  }

  bool isSlotBooked(String slot) {
    return bookedSlots.contains(slot);
  }

  Future<void> handleSlotSelection(String slot) async {
    // First refresh the slots
    await loadBookedSlots();

    if (isSlotBooked(slot)) {
      Get.snackbar(
        'Slot Booked',
        'This time slot is already booked',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    selectedSlot = slot;
    print('Attempting to book slot: $slot');
    await _processPayment();

    // Force refresh after booking
    await loadBookedSlots();
    print('Slots after booking: $bookedSlots');
    update();
  }

  Future<void> _processPayment() async {
    try {
      isProcessingPayment = true;
      update();

      // 1. Create payment intent on your backend
      final paymentIntent = await _createPaymentIntent();

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'E-Hospital',
          customerId: paymentIntent['customer'],
          customerEphemeralKeySecret: paymentIntent['ephemeralKey'],
          style: ThemeMode.light,
//          testEnv: true,
        ),
      );

      // 3. Display the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. On successful payment
      await _createAppointment();

      Get.snackbar(
          'Success',
          'Appointment booked successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white
      );

    } on StripeException catch (e) {
      Get.snackbar(
          'Payment Failed',
          e.error.localizedMessage ?? 'Payment cancelled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white
      );
    } catch (e) {
      print(e);
      Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white
      );
    } finally {
      isProcessingPayment = false;
      update();
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent() async {
    // In a real app, call your backend to create a PaymentIntent
    // This is just for testing - NEVER expose your secret key in the app

    // Test endpoint - replace with your actual backend endpoint
    const url = 'https://api.stripe.com/v1/payment_intents';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer sk_test_51RGfa1FSkLKjerwTOItvd8p5I3rnbn0uwu1einrptGnWwD2iTdt3Pl6fD4Ck4Tx27wGsSR9kTp04YoRMrMKsC9kO00wHtfj8F9',
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: {
        'amount': '1000', // $10.00 (in cents)
        'currency': 'usd',
        'payment_method_types[]': 'card',
      },
    );

    return json.decode(response.body);
  }

  Future<void> _createAppointment() async {
    try {
      String uniqueKey = FirebaseDatabase.instance.ref().push().key!;
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Doctor's appointment record
      await _dbRef
          .child(doctorSpecialization)
          .child(doctorKey)
          .child('Appointment')
          .child(uniqueKey)
          .set({
        'appointmentId': uniqueKey,
        'patientId': patientKey,
        'patientName': patientDetails['name'],
        'patientContact': patientDetails['contact'],
        'patientCnic': patientDetails['cnic'],
        'image_url': patientDetails['image_url'],
        'date': formattedDate,
        'time': selectedSlot,
        'status': 'upcoming',
        'createdAt': ServerValue.timestamp,
        'paymentStatus': 'completed',
        'doctorId': doctorKey,
        'doctorName': doctorDetails['name'],
        'specialization': doctorSpecialization
      });

      // Patient's appointment record
      await patientRef
          .child(patientKey)
          .child("Booked Appointment")
          .child(uniqueKey)
          .set({
        'appointmentId': uniqueKey,
        'doctorId': doctorKey,
        'doctorName': doctorDetails['name'],
        'specialization': doctorSpecialization,
        'image_url': doctorDetails['image_url'],
        'date': formattedDate,
        'time': selectedSlot,
        'status': 'upcoming',
        'createdAt': ServerValue.timestamp,
        'paymentStatus': 'completed',
        'contact': doctorDetails['contact'], // Doctor's contact
        'address': doctorDetails['address'] // Doctor's address
      });

      // Refresh UI
      await loadBookedSlots();
      selectedSlot = null;
      update();

      Get.back(); // Close the booking screen if needed
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      rethrow;
    }
  }
}

/* "pk_test_51RGfa1FSkLKjerwTafuoYIUpExXF0WRferAVCYTPYBxoccHsCBb89Y5k31zQDZStubJVDGJJzNX3Ag8peCGfWCeM00P2NDMygy" */