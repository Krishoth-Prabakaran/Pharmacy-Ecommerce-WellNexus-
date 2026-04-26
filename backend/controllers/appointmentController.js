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

    const userId = req.user?.user_id;
    const userRole = req.user?.role;

    if (!userId || !userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to create appointments.'
      });
    }

    let doctor_id;

    if (userRole === 'doctor') {
      doctor_id = userId;
      patient_id = req.body.patient_id;
      if (!patient_id) {
        return res.status(400).json({
          success: false,
          message: 'Please provide patient_id when a doctor creates an appointment.'
        });
      }
    } else if (userRole === 'patient') {
      patient_id = userId;
      doctor_id = req.body.doctor_id;
      if (!doctor_id) {
        return res.status(400).json({
          success: false,
          message: 'Please provide doctor_id when a patient requests an appointment.'
        });
      }
    } else {
      return res.status(403).json({
        success: false,
        message: 'Only patients and doctors may create appointments.'
      });
    }

    if (!appointment_date || !appointment_time) {
      return res.status(400).json({
        success: false,
        message: 'Please provide appointment_date and appointment_time.'
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
    const userId = req.user?.user_id;
    const userRole = req.user?.role;

    if (!userId || !userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to fetch doctor appointments.'
      });
    }

    if (userRole !== 'doctor') {
      return res.status(403).json({
        success: false,
        message: 'Only doctors may access their appointment list.'
      });
    }

    const doctor_id = userId;
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
    const userId = req.user?.user_id;
    const userRole = req.user?.role;

    if (!userId || !userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to access appointment details.'
      });
    }

    const appointment = await AppointmentModel.getAppointmentById(id);

    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    if (userRole === 'doctor' && appointment.doctor_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Doctor can only view their own appointments.'
      });
    }

    if (userRole === 'patient' && appointment.patient_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Patients can only view their own appointments.'
      });
    }

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
    const userId = req.user?.user_id;
    const userRole = req.user?.role;

    if (!userId || !userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to update appointment status.'
      });
    }

    const existingAppointment = await AppointmentModel.getAppointmentById(id);
    if (!existingAppointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    if (userRole === 'doctor' && existingAppointment.doctor_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Doctors may only update their own appointments.'
      });
    }

    if (userRole !== 'doctor' && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only doctors or admins may update appointment status.'
      });
    }

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
    const userId = req.user?.user_id;
    const userRole = req.user?.role;
    const { start, end } = req.query;

    if (!userId || !userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to fetch appointments by date range.'
      });
    }

    if (userRole !== 'doctor') {
      return res.status(403).json({
        success: false,
        message: 'Only doctors may access appointments by date range.'
      });
    }

    if (!start || !end) {
      return res.status(400).json({
        success: false,
        message: 'Please provide start and end dates'
      });
    }

    const appointments = await AppointmentModel.getAppointmentsByDateRange(userId, start, end);

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
    const userId = req.user?.user_id;
    const userRole = req.user?.role;

    if (!userId || !userRole) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to delete appointments.'
      });
    }

    const existingAppointment = await AppointmentModel.getAppointmentById(id);
    if (!existingAppointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    if (userRole === 'doctor' && existingAppointment.doctor_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Doctors may only delete their own appointments.'
      });
    }

    if (userRole !== 'doctor' && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only doctors or admins may delete appointments.'
      });
    }

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