const pool = require('./config/db');

async function createTables() {
  try {
    // Create prescriptions table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.prescriptions (
        prescription_id SERIAL NOT NULL,
        patient_id INTEGER NULL,
        doctor_name CHARACTER VARYING(120) NULL,
        prescription_date DATE NULL DEFAULT CURRENT_DATE,
        valid_until DATE NULL,
        sms_code CHARACTER VARYING(10) NOT NULL,
        status CHARACTER VARYING(20) NULL DEFAULT 'active'::CHARACTER VARYING,
        medicine_name CHARACTER VARYING(100) NULL,
        doctor_license INTEGER NULL,
        CONSTRAINT prescriptions_pkey PRIMARY KEY (prescription_id),
        CONSTRAINT prescriptions_sms_code_key UNIQUE (sms_code),
        CONSTRAINT prescriptions_doctor_license_fkey FOREIGN KEY (doctor_license) REFERENCES doctors ("doctor_License"),
        CONSTRAINT prescriptions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE CASCADE
      ) TABLESPACE pg_default;
    `);

    // Create prescription_items table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.prescription_items (
        item_id SERIAL NOT NULL,
        prescription_id INTEGER NULL,
        variant_id INTEGER NULL,
        dosage TEXT NULL,
        duration_days INTEGER NULL,
        CONSTRAINT prescription_items_pkey PRIMARY KEY (item_id),
        CONSTRAINT prescription_items_prescription_id_fkey FOREIGN KEY (prescription_id) REFERENCES prescriptions (prescription_id) ON DELETE CASCADE,
        CONSTRAINT prescription_items_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES medicine_variants (variant_id)
      ) TABLESPACE pg_default;
    `);

    // Create patients table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public.patients (
        patient_id SERIAL NOT NULL,
        first_name CHARACTER VARYING(50) NOT NULL,
        last_name CHARACTER VARYING(50) NOT NULL,
        phone CHARACTER VARYING(15) NOT NULL,
        email CHARACTER VARYING(100) NULL,
        date_of_birth DATE NULL,
        gender CHARACTER VARYING(10) NULL,
        user_id INTEGER NULL,
        CONSTRAINT patients_pkey PRIMARY KEY (patient_id),
        CONSTRAINT patients_phone_key UNIQUE (phone),
        CONSTRAINT unique_user_id UNIQUE (user_id),
        CONSTRAINT patients_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES users (user_id) NOT VALID,
        CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      ) TABLESPACE pg_default;
    `);

    // Create index
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_patients_user_id ON public.patients USING BTREE (user_id) TABLESPACE pg_default;
    `);

    console.log('Tables created successfully');
  } catch (error) {
    console.error('Error creating tables:', error);
  } finally {
    pool.end();
  }
}

createTables();