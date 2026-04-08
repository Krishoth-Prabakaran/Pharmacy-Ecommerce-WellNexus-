// =====================================================
// APPOINTMENT CONTROLLER
// =====================================================
// Handles HTTP requests for appointment operations
// =====================================================

const AppointmentModel = require('../models/appointmentModel');
const PatientModel = require('../models/patientModel');

/**
 * Create a new appointment
 * POST /api/appointments
 */
exports.createAppointment = async (req, res) => {
  try {
    const {
      patient_id,
      appointment_date,
      appointment_time,
      duration_minutes = 30,
      appointment_type = 'consultation',
      notes = ''
    } = req.body;

    // For now, we'll assume doctor_id comes from the request body or session
    // TODO: Implement proper authentication to get doctor_id from JWT
    const doctor_id = req.body.doctor_id || 1; // Temporary fallback

    // Validate required fields
    if (!patient_id || !appointment_date || !appointment_time) {
      return res.status(400).json({
        success: false,
        message: 'Please provide patient_id, appointment_date, and appointment_time'
      });
    }

    // Check if patient exists
    const patient = await PatientModel.getPatientById(patient_id);
    if (!patient) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found'
      });
    }

    // Create appointment
    const appointmentData = {
      doctor_id,
      patient_id,
      appointment_date,
      appointment_time,
      duration_minutes,
      appointment_type,
      notes,
      status: 'scheduled'
    };

    const appointment = await AppointmentModel.createAppointment(appointmentData);

    console.log(`✅ Appointment created for patient ${patient_id} with doctor ${doctor_id}`);

    res.status(201).json({
      success: true,
      message: 'Appointment created successfully',
      appointment
    });

  } catch (error) {
    console.error('❌ Error creating appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create appointment',
      error: error.message
    });
  }
};

/**
 * Get appointments by doctor
 * GET /api/appointments/doctor
 */
exports.getAppointmentsByDoctor = async (req, res) => {
  try {
    // TODO: Get doctor_id from authentication
    const doctor_id = req.query.doctor_id || 1; // Temporary fallback

    const { status, limit } = req.query;

    const appointments = await AppointmentModel.getAppointmentsByDoctor(
      doctor_id,
      status,
      limit ? parseInt(limit) : null
    );

    res.json({
      success: true,
      appointments
    });

  } catch (error) {
    console.error('❌ Error getting appointments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get appointments',
      error: error.message
    });
  }
};

/**
 * Get appointment by ID
 * GET /api/appointments/:id
 */
exports.getAppointmentById = async (req, res) => {
  try {
    const { id } = req.params;
    // TODO: Add authentication check
    // const doctor_id = req.user?.user_id;

    const appointment = await AppointmentModel.getAppointmentById(id);

    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    // TODO: Check if doctor owns this appointment
    // if (appointment.doctor_id !== doctor_id) {
    //   return res.status(403).json({
    //     success: false,
    //     message: 'Access denied'
    //   });
    // }

    res.json({
      success: true,
      appointment
    });

  } catch (error) {
    console.error('❌ Error getting appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get appointment',
      error: error.message
    });
  }
};

/**
 * Update appointment status
 * PUT /api/appointments/:id/status
 */
exports.updateAppointmentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    // TODO: Get doctor_id from authentication
    // const doctor_id = req.user?.user_id;

    // Check if appointment exists and belongs to doctor
    const existingAppointment = await AppointmentModel.getAppointmentById(id);
    if (!existingAppointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    // TODO: Check ownership
    // if (existingAppointment.doctor_id !== doctor_id) {
    //   return res.status(403).json({
    //     success: false,
    //     message: 'Access denied'
    //   });
    // }

    const updatedAppointment = await AppointmentModel.updateAppointmentStatus(id, status, notes);

    console.log(`✅ Appointment ${id} status updated to ${status}`);

    res.json({
      success: true,
      message: 'Appointment status updated successfully',
      appointment: updatedAppointment
    });

  } catch (error) {
    console.error('❌ Error updating appointment status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update appointment status',
      error: error.message
    });
  }
};

/**
 * Get appointments by date range
 * GET /api/appointments/range?start=2024-01-01&end=2024-01-31
 */
exports.getAppointmentsByDateRange = async (req, res) => {
  try {
    const doctor_id = req.user?.user_id;
    const { start, end } = req.query;

    if (!doctor_id) {
      return res.status(401).json({
        success: false,
        message: 'Doctor authentication required'
      });
    }

    if (!start || !end) {
      return res.status(400).json({
        success: false,
        message: 'Please provide start and end dates'
      });
    }

    const appointments = await AppointmentModel.getAppointmentsByDateRange(doctor_id, start, end);

    res.json({
      success: true,
      appointments
    });

  } catch (error) {
    console.error('❌ Error getting appointments by date range:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get appointments',
      error: error.message
    });
  }
};

/**
 * Delete appointment
 * DELETE /api/appointments/:id
 */
exports.deleteAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    // TODO: Get doctor_id from authentication
    // const doctor_id = req.user?.user_id;

    // Check if appointment exists and belongs to doctor
    const existingAppointment = await AppointmentModel.getAppointmentById(id);
    if (!existingAppointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    // TODO: Check ownership
    // if (existingAppointment.doctor_id !== doctor_id) {
    //   return res.status(403).json({
    //     success: false,
    //     message: 'Access denied'
    //   });
    // }

    await AppointmentModel.deleteAppointment(id);

    console.log(`✅ Appointment ${id} deleted`);

    res.json({
      success: true,
      message: 'Appointment deleted successfully'
    });

  } catch (error) {
    console.error('❌ Error deleting appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete appointment',
      error: error.message
    });
  }
};