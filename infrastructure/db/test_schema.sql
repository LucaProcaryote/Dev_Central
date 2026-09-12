-- Proves the schema enforces the rules its comments claim.
--
--   psql -d EHR_DB -v ON_ERROR_STOP=1 -f db/test_schema.sql
--
-- Runs entirely inside a transaction that is rolled back at the end, so it is
-- safe against a database with real data in it. Every assertion is written the
-- same way: attempt the write, and fail loudly if the database allowed it.
--
-- These are worth reading with the students. Each one is a bug that the
-- application layer could have shipped and the database refused to.

BEGIN;

-- A helper that runs a statement and complains if it did *not* fail.
CREATE OR REPLACE FUNCTION pg_temp.must_reject(what text, statement text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN others THEN
        RAISE NOTICE '  enforced: %', what;
        RETURN;
    END;
    RAISE EXCEPTION 'NOT ENFORCED: %', what;
END;
$$;

CREATE OR REPLACE FUNCTION pg_temp.must_accept(what text, statement text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE statement;
    RAISE NOTICE '  allowed:  %', what;
EXCEPTION WHEN others THEN
    RAISE EXCEPTION 'WRONGLY REJECTED: % (%)', what, SQLERRM;
END;
$$;

-- ---- Fixtures --------------------------------------------------------------

INSERT INTO wards (id, code, name, floor)
    VALUES ('t-w1', 'TW1', '{"en":"Test ward"}'::jsonb, 1);
INSERT INTO rooms (id, ward_id, number) VALUES ('t-r1', 't-w1', 'T101');
INSERT INTO beds (id, room_id, ward_id, label)
    VALUES ('t-b1', 't-r1', 't-w1', 'T101-A'),
           ('t-b2', 't-r1', 't-w1', 'T101-B');
INSERT INTO patients (id, mrn, family_name, given_name, birth_date)
    VALUES ('t-p1', 'TMRN1', 'Test', 'Alpha', '1980-01-01'),
           ('t-p2', 'TMRN2', 'Test', 'Beta',  '1975-05-05');
INSERT INTO encounters (id, patient_id, status, admission_date, bed_id)
    VALUES ('t-e1', 't-p1', 'in-progress', now(), 't-b1');
INSERT INTO cabinets (id, code, name, ward_id)
    VALUES ('t-c1', 'TC1', '{"en":"Test cabinet"}'::jsonb, 't-w1');
-- Fixtures must be created out here, not inside a must_reject block: that
-- helper swallows the exception by rolling back its own sub-transaction, which
-- would take any rows the block had inserted with it.
INSERT INTO prescriptions (id, patient_id, medication_code, medication,
                           dose_quantity, start_date)
    VALUES ('t-rx2', 't-p1', 'MED-0101', '{}'::jsonb, 1, now());

-- ---- The database must refuse these ---------------------------------------

\echo 'Rules the schema enforces:'

SELECT pg_temp.must_reject(
    'a patient cannot be admitted twice at once',
    $$INSERT INTO encounters (id, patient_id, status, admission_date)
      VALUES ('t-x1', 't-p1', 'in-progress', now())$$);

SELECT pg_temp.must_reject(
    'two patients cannot occupy one bed',
    $$INSERT INTO encounters (id, patient_id, status, admission_date, bed_id)
      VALUES ('t-x2', 't-p2', 'in-progress', now(), 't-b1')$$);

SELECT pg_temp.must_reject(
    'a stay cannot end before it began',
    $$INSERT INTO encounters (id, patient_id, status, admission_date, discharge_date)
      VALUES ('t-x3', 't-p2', 'finished', '2026-09-12', '2026-09-01')$$);

SELECT pg_temp.must_reject(
    'a finished stay must have a discharge date',
    $$INSERT INTO encounters (id, patient_id, status, admission_date)
      VALUES ('t-x4', 't-p2', 'finished', now())$$);

SELECT pg_temp.must_reject(
    'an occupied bed must name its occupant',
    $$UPDATE beds SET status = 'occupied' WHERE id = 't-b2'$$);

SELECT pg_temp.must_reject(
    'a bed that is not occupied must not name one',
    $$UPDATE beds SET current_patient_id = 't-p1' WHERE id = 't-b2'$$);

SELECT pg_temp.must_reject(
    'stock cannot go negative',
    $$INSERT INTO stock_items (id, cabinet_id, slot, medication_code, medication,
                               quantity_on_hand, expiry_date)
      VALUES ('t-s1', 't-c1', 'A-01', 'MED-0101', '{}'::jsonb, -5, now())$$);

SELECT pg_temp.must_reject(
    'one drawer cannot hold two different products',
    $$INSERT INTO stock_items (id, cabinet_id, slot, medication_code, medication,
                               quantity_on_hand, expiry_date)
      VALUES ('t-s2', 't-c1', 'A-02', 'MED-0101', '{}'::jsonb, 10, now()),
             ('t-s3', 't-c1', 'A-02', 'MED-0102', '{}'::jsonb, 10, now())$$);

SELECT pg_temp.must_reject(
    'a prescription cannot have a zero dose',
    $$INSERT INTO prescriptions (id, patient_id, medication_code, medication,
                                 dose_quantity, start_date)
      VALUES ('t-rx1', 't-p1', 'MED-0101', '{}'::jsonb, 0, now())$$);

SELECT pg_temp.must_reject(
    'a dispensed dose must record who handed it over',
    $$INSERT INTO dispenses (id, prescription_id, patient_id, quantity, status,
                             requested_at)
      VALUES ('t-d1', 't-rx2', 't-p1', 1, 'dispensed', now())$$);

SELECT pg_temp.must_reject(
    'a refused dose must record why',
    $$INSERT INTO dispenses (id, prescription_id, patient_id, quantity, status,
                             requested_at)
      VALUES ('t-d2', 't-rx2', 't-p1', 1, 'refused', now())$$);

SELECT pg_temp.must_reject(
    'gender is restricted to the FHIR value set',
    $$INSERT INTO patients (id, mrn, family_name, given_name, birth_date, gender)
      VALUES ('t-p9', 'TMRN9', 'X', 'Y', '1990-01-01', 'yes')$$);

SELECT pg_temp.must_reject(
    'a patient language must be one the hospital speaks',
    $$INSERT INTO patients (id, mrn, family_name, given_name, birth_date,
                            preferred_language)
      VALUES ('t-p8', 'TMRN8', 'X', 'Y', '1990-01-01', 'de')$$);

SELECT pg_temp.must_reject(
    'the medical record number is unique',
    $$INSERT INTO patients (id, mrn, family_name, given_name, birth_date)
      VALUES ('t-p7', 'TMRN1', 'X', 'Y', '1990-01-01')$$);

-- ---- And must allow these --------------------------------------------------

\echo 'And what it correctly permits:'

SELECT pg_temp.must_accept(
    'a patient may have a second stay once the first has finished',
    $$INSERT INTO encounters (id, patient_id, status, admission_date, discharge_date)
      VALUES ('t-ok1', 't-p1', 'finished', '2026-09-01', '2026-09-05')$$);

SELECT pg_temp.must_accept(
    'a finished stay may share a bed with the current occupant',
    $$INSERT INTO encounters (id, patient_id, status, admission_date,
                              discharge_date, bed_id)
      VALUES ('t-ok2', 't-p2', 'finished', now() - interval '2 days',
              now() - interval '1 day', 't-b1')$$);

SELECT pg_temp.must_accept(
    'a planned stay may be pencilled into an occupied bed',
    $$INSERT INTO encounters (id, patient_id, status, admission_date, bed_id)
      VALUES ('t-ok3', 't-p2', 'planned', now(), 't-b1')$$);

SELECT pg_temp.must_accept(
    'a refused dose with a reason is fine',
    $$INSERT INTO dispenses (id, prescription_id, patient_id, quantity, status,
                             requested_at, refusal_reason)
      VALUES ('t-ok4', 't-rx2', 't-p1', 1, 'refused', now(), 'Patient off the ward')$$);

\echo 'All schema rules behave as documented.'

ROLLBACK;
