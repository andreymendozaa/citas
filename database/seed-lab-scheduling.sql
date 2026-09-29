-- Datos sintéticos e idempotentes para recorrer los flujos S3 de agendamiento.
-- No contiene datos reales ni secretos de infraestructura.

START TRANSACTION;

INSERT INTO specialties(code, name, appointment_duration_minutes, is_general, requires_admin_approval, active)
VALUES
  ('LAB_MEDICINA_GENERAL', 'Medicina General Laboratorio', 30, TRUE, FALSE, TRUE),
  ('LAB_CARDIOLOGIA', 'Cardiología Laboratorio', 60, FALSE, TRUE, TRUE),
  ('LAB_DERMATOLOGIA', 'Dermatología Laboratorio', 30, FALSE, TRUE, TRUE)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  appointment_duration_minutes = VALUES(appointment_duration_minutes),
  is_general = VALUES(is_general),
  requires_admin_approval = VALUES(requires_admin_approval),
  active = VALUES(active);

-- El hash BCrypt pertenece exclusivamente a cuentas de laboratorio reutilizables.
INSERT INTO users(first_name, last_name, document_type, document_number, email, phone, password_hash, active, email_verified)
VALUES
  ('Ada', 'Administradora', 'CC', 'LAB-ADMIN-001', 'lab.admin@citas.test', '3000000001', '$2a$10$91CQwM/qrIygtj5SAJ9DdeVNK0HugNiJbNN0RIVmMbyWPyvaBMGpK', TRUE, TRUE),
  ('Uriel', 'Usuario', 'CC', 'LAB-USER-001', 'lab.usuario@citas.test', '3000000002', '$2a$10$91CQwM/qrIygtj5SAJ9DdeVNK0HugNiJbNN0RIVmMbyWPyvaBMGpK', TRUE, TRUE),
  ('Paula', 'Paciente', 'CC', 'LAB-USER-002', 'lab.paciente@citas.test', '3000000003', '$2a$10$91CQwM/qrIygtj5SAJ9DdeVNK0HugNiJbNN0RIVmMbyWPyvaBMGpK', TRUE, TRUE),
  ('Gabriel', 'General', 'CC', 'LAB-PRO-001', 'lab.general@citas.test', '3000000011', '$2a$10$91CQwM/qrIygtj5SAJ9DdeVNK0HugNiJbNN0RIVmMbyWPyvaBMGpK', TRUE, TRUE),
  ('Carolina', 'Cardio', 'CC', 'LAB-PRO-002', 'lab.cardio@citas.test', '3000000012', '$2a$10$91CQwM/qrIygtj5SAJ9DdeVNK0HugNiJbNN0RIVmMbyWPyvaBMGpK', TRUE, TRUE),
  ('Daniela', 'Derma', 'CC', 'LAB-PRO-003', 'lab.derma@citas.test', '3000000013', '$2a$10$91CQwM/qrIygtj5SAJ9DdeVNK0HugNiJbNN0RIVmMbyWPyvaBMGpK', TRUE, TRUE)
ON DUPLICATE KEY UPDATE
  first_name = VALUES(first_name), last_name = VALUES(last_name), phone = VALUES(phone), active = VALUES(active), email_verified = VALUES(email_verified);

INSERT IGNORE INTO user_roles(user_id, role_id)
SELECT u.id, r.id FROM users u JOIN roles r
WHERE (u.email = 'lab.admin@citas.test' AND r.code = 'ADMIN')
   OR (u.email IN ('lab.usuario@citas.test', 'lab.paciente@citas.test') AND r.code = 'USER')
   OR (u.email IN ('lab.general@citas.test', 'lab.cardio@citas.test', 'lab.derma@citas.test') AND r.code = 'PROFESSIONAL');

INSERT INTO professionals(user_id, professional_code, license_number, active)
SELECT id, 'LAB-GEN-001', 'LAB-LIC-GEN-001', TRUE FROM users WHERE email = 'lab.general@citas.test'
ON DUPLICATE KEY UPDATE active = VALUES(active);
INSERT INTO professionals(user_id, professional_code, license_number, active)
SELECT id, 'LAB-CARD-001', 'LAB-LIC-CARD-001', TRUE FROM users WHERE email = 'lab.cardio@citas.test'
ON DUPLICATE KEY UPDATE active = VALUES(active);
INSERT INTO professionals(user_id, professional_code, license_number, active)
SELECT id, 'LAB-DERM-001', 'LAB-LIC-DERM-001', TRUE FROM users WHERE email = 'lab.derma@citas.test'
ON DUPLICATE KEY UPDATE active = VALUES(active);

INSERT INTO professional_specialties(professional_id, specialty_id, is_primary, active)
SELECT p.id, s.id, TRUE, TRUE FROM professionals p JOIN specialties s WHERE p.professional_code = 'LAB-GEN-001' AND s.code = 'LAB_MEDICINA_GENERAL'
ON DUPLICATE KEY UPDATE is_primary = VALUES(is_primary), active = VALUES(active);
INSERT INTO professional_specialties(professional_id, specialty_id, is_primary, active)
SELECT p.id, s.id, TRUE, TRUE FROM professionals p JOIN specialties s WHERE p.professional_code = 'LAB-CARD-001' AND s.code = 'LAB_CARDIOLOGIA'
ON DUPLICATE KEY UPDATE is_primary = VALUES(is_primary), active = VALUES(active);
INSERT INTO professional_specialties(professional_id, specialty_id, is_primary, active)
SELECT p.id, s.id, TRUE, TRUE FROM professionals p JOIN specialties s WHERE p.professional_code = 'LAB-DERM-001' AND s.code = 'LAB_DERMATOLOGIA'
ON DUPLICATE KEY UPDATE is_primary = VALUES(is_primary), active = VALUES(active);

INSERT INTO professional_locations(professional_id, location_id, active)
SELECT p.id, 1, TRUE FROM professionals p WHERE p.professional_code IN ('LAB-GEN-001', 'LAB-DERM-001')
ON DUPLICATE KEY UPDATE active = VALUES(active);
INSERT INTO professional_locations(professional_id, location_id, active)
SELECT p.id, 2, TRUE FROM professionals p WHERE p.professional_code = 'LAB-CARD-001'
ON DUPLICATE KEY UPDATE active = VALUES(active);

SET @general_day = DATE_ADD(CURDATE(), INTERVAL 7 DAY);
SET @derma_day = DATE_ADD(CURDATE(), INTERVAL 8 DAY);

INSERT INTO availability_blocks(professional_id, location_id, available_date, start_time, end_time, active)
SELECT p.id, 1, @general_day, '08:00:00', '12:00:00', TRUE FROM professionals p
WHERE p.professional_code = 'LAB-GEN-001' AND NOT EXISTS (
  SELECT 1 FROM availability_blocks b WHERE b.professional_id = p.id AND b.location_id = 1 AND b.available_date = @general_day AND b.start_time = '08:00:00'
);
INSERT INTO availability_blocks(professional_id, location_id, available_date, start_time, end_time, active)
SELECT p.id, 2, @general_day, '09:00:00', '13:00:00', TRUE FROM professionals p
WHERE p.professional_code = 'LAB-CARD-001' AND NOT EXISTS (
  SELECT 1 FROM availability_blocks b WHERE b.professional_id = p.id AND b.location_id = 2 AND b.available_date = @general_day AND b.start_time = '09:00:00'
);
INSERT INTO availability_blocks(professional_id, location_id, available_date, start_time, end_time, active)
SELECT p.id, 1, @derma_day, '14:00:00', '17:00:00', TRUE FROM professionals p
WHERE p.professional_code = 'LAB-DERM-001' AND NOT EXISTS (
  SELECT 1 FROM availability_blocks b WHERE b.professional_id = p.id AND b.location_id = 1 AND b.available_date = @derma_day AND b.start_time = '14:00:00'
);

INSERT IGNORE INTO professional_slots(availability_block_id, start_at, end_at)
SELECT b.id, TIMESTAMP(b.available_date, '08:00:00'), TIMESTAMP(b.available_date, '08:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '08:30:00'), TIMESTAMP(b.available_date, '09:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '09:00:00'), TIMESTAMP(b.available_date, '09:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '09:30:00'), TIMESTAMP(b.available_date, '10:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '10:00:00'), TIMESTAMP(b.available_date, '10:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '10:30:00'), TIMESTAMP(b.available_date, '11:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '11:00:00'), TIMESTAMP(b.available_date, '11:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '11:30:00'), TIMESTAMP(b.available_date, '12:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-GEN-001' AND b.available_date = @general_day;

INSERT IGNORE INTO professional_slots(availability_block_id, start_at, end_at)
SELECT b.id, TIMESTAMP(b.available_date, '09:00:00'), TIMESTAMP(b.available_date, '09:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '09:30:00'), TIMESTAMP(b.available_date, '10:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '10:00:00'), TIMESTAMP(b.available_date, '10:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '10:30:00'), TIMESTAMP(b.available_date, '11:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '11:00:00'), TIMESTAMP(b.available_date, '11:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '11:30:00'), TIMESTAMP(b.available_date, '12:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '12:00:00'), TIMESTAMP(b.available_date, '12:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '12:30:00'), TIMESTAMP(b.available_date, '13:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-CARD-001' AND b.available_date = @general_day;

INSERT IGNORE INTO professional_slots(availability_block_id, start_at, end_at)
SELECT b.id, TIMESTAMP(b.available_date, '14:00:00'), TIMESTAMP(b.available_date, '14:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-DERM-001' AND b.available_date = @derma_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '14:30:00'), TIMESTAMP(b.available_date, '15:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-DERM-001' AND b.available_date = @derma_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '15:00:00'), TIMESTAMP(b.available_date, '15:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-DERM-001' AND b.available_date = @derma_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '15:30:00'), TIMESTAMP(b.available_date, '16:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-DERM-001' AND b.available_date = @derma_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '16:00:00'), TIMESTAMP(b.available_date, '16:30:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-DERM-001' AND b.available_date = @derma_day
UNION ALL SELECT b.id, TIMESTAMP(b.available_date, '16:30:00'), TIMESTAMP(b.available_date, '17:00:00') FROM availability_blocks b JOIN professionals p ON p.id = b.professional_id WHERE p.professional_code = 'LAB-DERM-001' AND b.available_date = @derma_day;

SET @admin_id = (SELECT id FROM users WHERE email = 'lab.admin@citas.test');
SET @user_one_id = (SELECT id FROM users WHERE email = 'lab.usuario@citas.test');
SET @user_two_id = (SELECT id FROM users WHERE email = 'lab.paciente@citas.test');
SET @general_professional_id = (SELECT id FROM professionals WHERE professional_code = 'LAB-GEN-001');
SET @cardio_professional_id = (SELECT id FROM professionals WHERE professional_code = 'LAB-CARD-001');
SET @derma_professional_id = (SELECT id FROM professionals WHERE professional_code = 'LAB-DERM-001');
SET @general_specialty_id = (SELECT id FROM specialties WHERE code = 'LAB_MEDICINA_GENERAL');
SET @cardio_specialty_id = (SELECT id FROM specialties WHERE code = 'LAB_CARDIOLOGIA');
SET @derma_specialty_id = (SELECT id FROM specialties WHERE code = 'LAB_DERMATOLOGIA');
SET @requested_status_id = (SELECT id FROM appointment_statuses WHERE code = 'REQUESTED');
SET @approved_status_id = (SELECT id FROM appointment_statuses WHERE code = 'APPROVED');
SET @rejected_status_id = (SELECT id FROM appointment_statuses WHERE code = 'REJECTED');

INSERT INTO appointments(patient_user_id, professional_id, location_id, specialty_id, status_id, reason, scheduled_start_at, scheduled_end_at, created_by_user_id, approved_by_user_id, approved_at)
SELECT @user_one_id, @general_professional_id, 1, @general_specialty_id, @approved_status_id, 'LAB: cita general aprobada', TIMESTAMP(@general_day, '08:00:00'), TIMESTAMP(@general_day, '08:30:00'), @user_one_id, @user_one_id, NOW()
WHERE NOT EXISTS (SELECT 1 FROM appointments WHERE reason = 'LAB: cita general aprobada');
INSERT INTO appointments(patient_user_id, professional_id, location_id, specialty_id, status_id, reason, scheduled_start_at, scheduled_end_at, created_by_user_id)
SELECT @user_one_id, @cardio_professional_id, 2, @cardio_specialty_id, @requested_status_id, 'LAB: solicitud especializada pendiente', TIMESTAMP(@general_day, '09:00:00'), TIMESTAMP(@general_day, '10:00:00'), @user_one_id
WHERE NOT EXISTS (SELECT 1 FROM appointments WHERE reason = 'LAB: solicitud especializada pendiente');
INSERT INTO appointments(patient_user_id, professional_id, location_id, specialty_id, status_id, reason, scheduled_start_at, scheduled_end_at, created_by_user_id, approved_by_user_id, approved_at)
SELECT @user_two_id, @cardio_professional_id, 2, @cardio_specialty_id, @approved_status_id, 'LAB: solicitud especializada aprobada', TIMESTAMP(@general_day, '10:00:00'), TIMESTAMP(@general_day, '11:00:00'), @user_two_id, @admin_id, NOW()
WHERE NOT EXISTS (SELECT 1 FROM appointments WHERE reason = 'LAB: solicitud especializada aprobada');
INSERT INTO appointments(patient_user_id, professional_id, location_id, specialty_id, status_id, reason, scheduled_start_at, scheduled_end_at, created_by_user_id, approved_by_user_id, approved_at)
SELECT @user_two_id, @derma_professional_id, 1, @derma_specialty_id, @rejected_status_id, 'LAB: solicitud especializada rechazada', TIMESTAMP(@derma_day, '14:00:00'), TIMESTAMP(@derma_day, '14:30:00'), @user_two_id, @admin_id, NOW()
WHERE NOT EXISTS (SELECT 1 FROM appointments WHERE reason = 'LAB: solicitud especializada rechazada');

SET @general_appointment_id = (SELECT id FROM appointments WHERE reason = 'LAB: cita general aprobada');
SET @requested_appointment_id = (SELECT id FROM appointments WHERE reason = 'LAB: solicitud especializada pendiente');
SET @approved_appointment_id = (SELECT id FROM appointments WHERE reason = 'LAB: solicitud especializada aprobada');
SET @rejected_appointment_id = (SELECT id FROM appointments WHERE reason = 'LAB: solicitud especializada rechazada');

UPDATE professional_slots SET appointment_id = @general_appointment_id WHERE availability_block_id IN (SELECT id FROM availability_blocks WHERE professional_id = @general_professional_id AND available_date = @general_day) AND start_at = TIMESTAMP(@general_day, '08:00:00');
UPDATE professional_slots SET appointment_id = @requested_appointment_id WHERE availability_block_id IN (SELECT id FROM availability_blocks WHERE professional_id = @cardio_professional_id AND available_date = @general_day) AND start_at IN (TIMESTAMP(@general_day, '09:00:00'), TIMESTAMP(@general_day, '09:30:00'));
UPDATE professional_slots SET appointment_id = @approved_appointment_id WHERE availability_block_id IN (SELECT id FROM availability_blocks WHERE professional_id = @cardio_professional_id AND available_date = @general_day) AND start_at IN (TIMESTAMP(@general_day, '10:00:00'), TIMESTAMP(@general_day, '10:30:00'));

INSERT INTO appointment_status_history(appointment_id, status_id, changed_by_user_id, change_source, reason)
SELECT @general_appointment_id, @approved_status_id, @user_one_id, 'SYSTEM', 'LAB: aprobación automática' WHERE NOT EXISTS (SELECT 1 FROM appointment_status_history WHERE appointment_id = @general_appointment_id AND status_id = @approved_status_id);
INSERT INTO appointment_status_history(appointment_id, status_id, changed_by_user_id, change_source, reason)
SELECT @requested_appointment_id, @requested_status_id, @user_one_id, 'USER', 'LAB: pendiente de decisión ADMIN' WHERE NOT EXISTS (SELECT 1 FROM appointment_status_history WHERE appointment_id = @requested_appointment_id AND status_id = @requested_status_id);
INSERT INTO appointment_status_history(appointment_id, status_id, changed_by_user_id, change_source, reason)
SELECT @approved_appointment_id, @requested_status_id, @user_two_id, 'USER', 'LAB: solicitud especializada creada' WHERE NOT EXISTS (SELECT 1 FROM appointment_status_history WHERE appointment_id = @approved_appointment_id AND status_id = @requested_status_id);
INSERT INTO appointment_status_history(appointment_id, status_id, changed_by_user_id, change_source, reason)
SELECT @approved_appointment_id, @approved_status_id, @admin_id, 'ADMIN', 'LAB: solicitud aprobada' WHERE NOT EXISTS (SELECT 1 FROM appointment_status_history WHERE appointment_id = @approved_appointment_id AND status_id = @approved_status_id);
INSERT INTO appointment_status_history(appointment_id, status_id, changed_by_user_id, change_source, reason)
SELECT @rejected_appointment_id, @requested_status_id, @user_two_id, 'USER', 'LAB: solicitud especializada creada' WHERE NOT EXISTS (SELECT 1 FROM appointment_status_history WHERE appointment_id = @rejected_appointment_id AND status_id = @requested_status_id);
INSERT INTO appointment_status_history(appointment_id, status_id, changed_by_user_id, change_source, reason)
SELECT @rejected_appointment_id, @rejected_status_id, @admin_id, 'ADMIN', 'LAB: motivo de rechazo sintético' WHERE NOT EXISTS (SELECT 1 FROM appointment_status_history WHERE appointment_id = @rejected_appointment_id AND status_id = @rejected_status_id);

COMMIT;
