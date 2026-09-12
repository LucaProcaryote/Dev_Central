-- Mini-Hospital 2026 - database schema
--
-- The same schema is applied to all five databases (EHR_DB, ADT_DB, PHARM_DB,
-- EAI_DB, DEV_DB). Each application owns and writes only the tables its job
-- requires; the rest are kept in step by the integration flows.
--
-- That is not a shortcut. It is how hospital IT actually works: every system
-- keeps its own copy of the patient master, and an ADT feed reconciles them.
-- Giving each application its own database makes that visible - a student who
-- admits a patient in ADT and then cannot find them in the EHR has just
-- discovered why interface engines exist, which is the lesson.
--
--   EHR_DB    patients, allergies, encounters, observations, prescriptions,
--             clinical_notes
--   ADT_DB    patients, wards, rooms, beds, encounters, movements
--   PHARM_DB  patients, medications, prescriptions, dispenses, cabinets,
--             stock_items
--   EAI_DB    integration_flows, integration_messages (+ patients, for the
--             enricher node)
--   DEV_DB    devices, observations, patients
--
-- Applied by db/apply.sh, which creates the databases and loads this file and
-- seed.sql into each of them.

-- ---------------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------------

-- Trilingual content lives in jsonb as {"en": …, "fr": …, "nl": …}. Three
-- columns per label would work too, but a single jsonb keeps the shape
-- identical to what the applications and the REST API already exchange, and
-- adding a fourth language later would not need a migration on every table.
CREATE TABLE IF NOT EXISTS wards (
    id              text PRIMARY KEY,
    code            text        NOT NULL UNIQUE,
    name            jsonb       NOT NULL,
    floor           integer     NOT NULL DEFAULT 0,
    specialty       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    phone_extension text
);

CREATE TABLE IF NOT EXISTS rooms (
    id           text PRIMARY KEY,
    ward_id      text    NOT NULL REFERENCES wards (id) ON DELETE CASCADE,
    number       text    NOT NULL,
    is_isolation boolean NOT NULL DEFAULT false,
    UNIQUE (ward_id, number)
);

CREATE TABLE IF NOT EXISTS beds (
    id                   text PRIMARY KEY,
    room_id              text NOT NULL REFERENCES rooms (id) ON DELETE CASCADE,
    ward_id              text NOT NULL REFERENCES wards (id) ON DELETE CASCADE,
    label                text NOT NULL,
    status               text NOT NULL DEFAULT 'free'
                              CHECK (status IN ('free', 'occupied', 'cleaning', 'blocked')),
    current_encounter_id text,
    current_patient_id   text,
    -- An occupied bed must say who is in it, and a bed that is not occupied
    -- must not claim an occupant. Without this the bed board can disagree with
    -- the patient list, which is the single most confusing failure in an ADT
    -- system.
    CONSTRAINT bed_occupancy_consistent CHECK (
        (status = 'occupied' AND current_patient_id IS NOT NULL)
        OR (status <> 'occupied' AND current_patient_id IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS beds_ward_status_idx ON beds (ward_id, status);

CREATE TABLE IF NOT EXISTS medications (
    code          text PRIMARY KEY,
    name          jsonb   NOT NULL,
    form          jsonb   NOT NULL DEFAULT '{}'::jsonb,
    strength      text    NOT NULL DEFAULT '',
    atc_code      text    NOT NULL DEFAULT '',
    is_controlled boolean NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS medications_atc_idx ON medications (atc_code);

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS patients (
    id                   text PRIMARY KEY,
    mrn                  text NOT NULL UNIQUE,
    national_number      text UNIQUE,
    family_name          text NOT NULL,
    given_name           text NOT NULL,
    gender               text NOT NULL DEFAULT 'unknown'
                              CHECK (gender IN ('male', 'female', 'other', 'unknown')),
    birth_date           date NOT NULL,
    address              jsonb NOT NULL DEFAULT '{}'::jsonb,
    phone                text,
    email                text,
    -- The language the patient should be addressed in, which is not the
    -- language the clinician has chosen for the interface.
    preferred_language   text NOT NULL DEFAULT 'fr'
                              CHECK (preferred_language IN ('en', 'fr', 'nl')),
    blood_group          text,
    general_practitioner text,
    deceased_date        timestamptz,
    photo_url            text,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now()
);

-- Patients are searched by name far more often than by anything else.
CREATE INDEX IF NOT EXISTS patients_family_name_idx ON patients (lower(family_name));
CREATE INDEX IF NOT EXISTS patients_given_name_idx ON patients (lower(given_name));

CREATE TABLE IF NOT EXISTS allergies (
    id            text PRIMARY KEY,
    patient_id    text  NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    substance     jsonb NOT NULL,
    reaction      jsonb NOT NULL DEFAULT '{}'::jsonb,
    criticality   text  NOT NULL DEFAULT 'unable-to-assess'
                        CHECK (criticality IN ('low', 'high', 'unable-to-assess')),
    recorded_date timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS allergies_patient_idx ON allergies (patient_id);

CREATE TABLE IF NOT EXISTS staff (
    uid                 text PRIMARY KEY,
    email               text NOT NULL UNIQUE,
    display_name        text NOT NULL,
    role                text NOT NULL,
    ward_ids            text[] NOT NULL DEFAULT '{}',
    preferred_language  text NOT NULL DEFAULT 'en',
    registration_number text
);

-- ---------------------------------------------------------------------------
-- The stay
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS encounters (
    id                     text PRIMARY KEY,
    patient_id             text NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    status                 text NOT NULL
                                CHECK (status IN ('planned', 'in-progress', 'onleave',
                                                  'finished', 'cancelled')),
    encounter_class        text NOT NULL DEFAULT 'IMP',
    admission_date         timestamptz NOT NULL,
    discharge_date         timestamptz,
    ward_id                text,
    room_id                text,
    bed_id                 text,
    admitting_practitioner text,
    attending_practitioner text,
    reason                 text,
    discharge_disposition  text,
    visit_number           text,
    -- A stay cannot end before it began.
    CONSTRAINT encounter_period_ordered CHECK (
        discharge_date IS NULL OR discharge_date >= admission_date
    ),
    -- A finished stay has a discharge date; an active one does not.
    CONSTRAINT encounter_discharge_consistent CHECK (
        (status = 'finished' AND discharge_date IS NOT NULL)
        OR (status <> 'finished')
    )
);

CREATE INDEX IF NOT EXISTS encounters_patient_idx ON encounters (patient_id);
CREATE INDEX IF NOT EXISTS encounters_ward_idx ON encounters (ward_id);

-- One active stay per patient, enforced by the database rather than by hope.
-- A partial unique index is the right tool: it constrains only the rows where
-- the rule applies and leaves discharged stays alone.
CREATE UNIQUE INDEX IF NOT EXISTS encounters_one_active_per_patient
    ON encounters (patient_id)
    WHERE status IN ('in-progress', 'onleave');

-- And one patient per bed, for the same reason.
CREATE UNIQUE INDEX IF NOT EXISTS encounters_one_active_per_bed
    ON encounters (bed_id)
    WHERE bed_id IS NOT NULL AND status IN ('in-progress', 'onleave');

-- Movements are append-only: replaying them reconstructs the whole journey,
-- which is the audit trail a hospital is required to keep.
CREATE TABLE IF NOT EXISTS movements (
    id           text PRIMARY KEY,
    encounter_id text NOT NULL REFERENCES encounters (id) ON DELETE CASCADE,
    patient_id   text NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    type         text NOT NULL
                      CHECK (type IN ('admission', 'transfer', 'discharge',
                                      'cancelAdmission', 'preAdmission')),
    occurred_at  timestamptz NOT NULL,
    performed_by text NOT NULL DEFAULT '',
    from_ward_id text,
    from_bed_id  text,
    to_ward_id   text,
    to_bed_id    text,
    note         text
);

CREATE INDEX IF NOT EXISTS movements_encounter_idx ON movements (encounter_id);
CREATE INDEX IF NOT EXISTS movements_occurred_idx  ON movements (occurred_at DESC);

-- ---------------------------------------------------------------------------
-- Clinical content
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS observations (
    id                  text PRIMARY KEY,
    patient_id          text NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    encounter_id        text,
    -- The application-level name; the LOINC code it maps to is fixed in
    -- VitalSignType and re-derived on the way out, so it cannot drift.
    type                text NOT NULL,
    value               double precision NOT NULL,
    unit                text NOT NULL DEFAULT '',
    effective_date_time timestamptz NOT NULL,
    device_id           text,
    performer           text,
    status              text NOT NULL DEFAULT 'final',
    note                text
);

-- The patient fiche always asks for one patient's readings, newest first.
CREATE INDEX IF NOT EXISTS observations_patient_time_idx
    ON observations (patient_id, effective_date_time DESC);
CREATE INDEX IF NOT EXISTS observations_patient_type_time_idx
    ON observations (patient_id, type, effective_date_time DESC);
CREATE INDEX IF NOT EXISTS observations_device_idx ON observations (device_id);

CREATE TABLE IF NOT EXISTS prescriptions (
    id                text PRIMARY KEY,
    patient_id        text NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    encounter_id      text,
    medication_code   text NOT NULL,
    -- The formulary entry is copied in, not only referenced: a prescription
    -- has to remain readable exactly as written even after the formulary
    -- changes strength or is reworded.
    medication        jsonb NOT NULL,
    dose_quantity     double precision NOT NULL CHECK (dose_quantity > 0),
    dose_unit         text NOT NULL DEFAULT '',
    frequency_per_day integer NOT NULL DEFAULT 1 CHECK (frequency_per_day >= 0),
    route             text NOT NULL DEFAULT 'oral',
    start_date        timestamptz NOT NULL,
    end_date          timestamptz,
    prescriber        text NOT NULL DEFAULT '',
    status            text NOT NULL DEFAULT 'draft'
                           CHECK (status IN ('draft', 'active', 'on-hold',
                                             'completed', 'cancelled')),
    is_prn            boolean NOT NULL DEFAULT false,
    indication        text,
    instructions      text,
    CONSTRAINT prescription_period_ordered CHECK (
        end_date IS NULL OR end_date >= start_date
    )
);

CREATE INDEX IF NOT EXISTS prescriptions_patient_idx ON prescriptions (patient_id);
CREATE INDEX IF NOT EXISTS prescriptions_active_idx
    ON prescriptions (patient_id) WHERE status = 'active';

CREATE TABLE IF NOT EXISTS clinical_notes (
    id            text PRIMARY KEY,
    patient_id    text NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    encounter_id  text,
    type          text NOT NULL DEFAULT 'progress',
    title         text NOT NULL DEFAULT '',
    body          text NOT NULL DEFAULT '',
    author_name   text NOT NULL DEFAULT '',
    author_role   text NOT NULL DEFAULT '',
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz,
    is_signed     boolean NOT NULL DEFAULT false,
    -- Clinical text is stored in the language it was written in and never
    -- machine-translated; the column records which that is so the reader can
    -- be told.
    language      text NOT NULL DEFAULT 'fr'
                       CHECK (language IN ('en', 'fr', 'nl'))
);

CREATE INDEX IF NOT EXISTS clinical_notes_patient_idx
    ON clinical_notes (patient_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Pharmacy
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cabinets (
    id                  text PRIMARY KEY,
    code                text NOT NULL UNIQUE,
    name                jsonb NOT NULL,
    ward_id             text NOT NULL,
    is_locked           boolean NOT NULL DEFAULT true,
    temperature_celsius double precision
);

CREATE TABLE IF NOT EXISTS stock_items (
    id               text PRIMARY KEY,
    cabinet_id       text NOT NULL REFERENCES cabinets (id) ON DELETE CASCADE,
    slot             text NOT NULL,
    medication_code  text NOT NULL,
    medication       jsonb NOT NULL,
    quantity_on_hand integer NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    par_level        integer NOT NULL DEFAULT 0 CHECK (par_level >= 0),
    expiry_date      timestamptz NOT NULL,
    lot_number       text NOT NULL DEFAULT '',
    -- One product per slot, and one slot per product within a cabinet: a
    -- drawer holding two different drugs is the thing these cabinets exist to
    -- prevent.
    UNIQUE (cabinet_id, slot),
    UNIQUE (cabinet_id, medication_code)
);

CREATE INDEX IF NOT EXISTS stock_items_low_idx
    ON stock_items (cabinet_id) WHERE quantity_on_hand <= par_level;

CREATE TABLE IF NOT EXISTS dispenses (
    id              text PRIMARY KEY,
    prescription_id text NOT NULL REFERENCES prescriptions (id) ON DELETE CASCADE,
    patient_id      text NOT NULL REFERENCES patients (id) ON DELETE CASCADE,
    quantity        double precision NOT NULL CHECK (quantity > 0),
    status          text NOT NULL DEFAULT 'requested'
                         CHECK (status IN ('requested', 'preparation', 'dispensed',
                                           'refused', 'returned')),
    requested_at    timestamptz NOT NULL,
    dispensed_at    timestamptz,
    dispensed_by    text,
    cabinet_id      text,
    slot            text,
    refusal_reason  text,
    lot_number      text,
    -- A dose recorded as handed over must say when and by whom; a refusal must
    -- say why. Anything else is an unauditable medication record.
    CONSTRAINT dispense_completion_consistent CHECK (
        (status <> 'dispensed')
        OR (dispensed_at IS NOT NULL AND dispensed_by IS NOT NULL)
    ),
    CONSTRAINT dispense_refusal_has_reason CHECK (
        (status <> 'refused') OR (refusal_reason IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS dispenses_queue_idx
    ON dispenses (cabinet_id, requested_at DESC) WHERE status = 'requested';
CREATE INDEX IF NOT EXISTS dispenses_patient_idx ON dispenses (patient_id);

-- ---------------------------------------------------------------------------
-- Devices
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS devices (
    id                  text PRIMARY KEY,
    code                text NOT NULL UNIQUE,
    kind                text NOT NULL,
    manufacturer        text NOT NULL DEFAULT '',
    model               text NOT NULL DEFAULT '',
    serial_number       text NOT NULL DEFAULT '',
    status              text NOT NULL DEFAULT 'offline'
                             CHECK (status IN ('active', 'standby', 'maintenance', 'offline')),
    assigned_patient_id text,
    assigned_bed_id     text,
    ward_id             text,
    last_seen_at        timestamptz,
    battery_percent     integer CHECK (battery_percent BETWEEN 0 AND 100),
    owner_student       text
);

-- ---------------------------------------------------------------------------
-- Integration
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS integration_flows (
    id                 text PRIMARY KEY,
    name               jsonb NOT NULL,
    description        jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_enabled         boolean NOT NULL DEFAULT true,
    -- The canvas is stored as jsonb rather than normalised into node and edge
    -- tables. A flow is only ever read and written whole, and keeping it in
    -- one document means the editor's undo, the REST payload and the stored
    -- row are all the same shape.
    nodes              jsonb NOT NULL DEFAULT '[]'::jsonb,
    connections        jsonb NOT NULL DEFAULT '[]'::jsonb,
    updated_at         timestamptz NOT NULL DEFAULT now(),
    messages_processed integer NOT NULL DEFAULT 0,
    messages_failed    integer NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS integration_messages (
    id           text PRIMARY KEY,
    message_type text NOT NULL,
    source_app   text NOT NULL,
    target_app   text,
    flow_id      text,
    patient_id   text,
    payload      jsonb NOT NULL DEFAULT '{}'::jsonb,
    -- The step-by-step record of what each node did. This is what makes the
    -- engine teachable, so it is stored, not just displayed.
    trace        jsonb NOT NULL DEFAULT '[]'::jsonb,
    status       text NOT NULL DEFAULT 'received'
                      CHECK (status IN ('received', 'processing', 'delivered',
                                        'filtered', 'failed')),
    received_at  timestamptz NOT NULL DEFAULT now(),
    processed_at timestamptz,
    error        text
);

CREATE INDEX IF NOT EXISTS integration_messages_received_idx
    ON integration_messages (received_at DESC);
CREATE INDEX IF NOT EXISTS integration_messages_flow_idx
    ON integration_messages (flow_id, received_at DESC);
CREATE INDEX IF NOT EXISTS integration_messages_failed_idx
    ON integration_messages (received_at DESC) WHERE status = 'failed';
