-- =============================================================
--  School Management System – Database Schema
--  Database: MySQL 8.0+ / MariaDB 10.5+
-- =============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================
-- 1. USERS & ROLES
-- =============================================================

CREATE TABLE IF NOT EXISTS roles (
    id          TINYINT UNSIGNED    NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)         NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_roles_name (name)
);

INSERT INTO roles (name) VALUES
    ('Admin'),
    ('Teacher'),
    ('Student'),
    ('Parent'),
    ('Accountant')
ON DUPLICATE KEY UPDATE name = name;

CREATE TABLE IF NOT EXISTS users (
    id              INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    first_name      VARCHAR(100)        NOT NULL,
    last_name       VARCHAR(100)        NOT NULL,
    email           VARCHAR(255)        NOT NULL,
    phone           VARCHAR(20)         DEFAULT NULL,
    password_hash   VARCHAR(255)        NOT NULL,
    status          ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    created_by      INT UNSIGNED        DEFAULT NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_email (email)
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id     INT UNSIGNED        NOT NULL,
    role_id     TINYINT UNSIGNED    NOT NULL,
    assigned_at DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
);

-- =============================================================
-- 2. ACADEMIC STRUCTURE
-- =============================================================

CREATE TABLE IF NOT EXISTS academic_years (
    id          SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    name        VARCHAR(20)         NOT NULL,  -- e.g. "2025-2026"
    start_date  DATE                NOT NULL,
    end_date    DATE                NOT NULL,
    is_current  TINYINT(1)          NOT NULL DEFAULT 0,
    is_active   TINYINT(1)          NOT NULL DEFAULT 1,
    created_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_academic_years_name (name)
);

CREATE TABLE IF NOT EXISTS classes (
    id                  SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    name                VARCHAR(100)        NOT NULL,
    grade_level         TINYINT UNSIGNED    NOT NULL,  -- e.g. 1-12
    section             CHAR(5)             NOT NULL,  -- e.g. "A", "B"
    academic_year_id    SMALLINT UNSIGNED   NOT NULL,
    is_active           TINYINT(1)          NOT NULL DEFAULT 1,
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_classes_grade_section_year (grade_level, section, academic_year_id),
    CONSTRAINT fk_classes_year FOREIGN KEY (academic_year_id) REFERENCES academic_years (id)
);

CREATE TABLE IF NOT EXISTS subjects (
    id          SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    name        VARCHAR(150)        NOT NULL,
    code        VARCHAR(20)         NOT NULL,
    is_active   TINYINT(1)          NOT NULL DEFAULT 1,
    created_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_subjects_code (code)
);

CREATE TABLE IF NOT EXISTS class_subjects (
    id          INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    class_id    SMALLINT UNSIGNED   NOT NULL,
    subject_id  SMALLINT UNSIGNED   NOT NULL,
    teacher_id  INT UNSIGNED        NOT NULL,  -- FK -> users.id (teacher)
    is_active   TINYINT(1)          NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_class_subject_teacher (class_id, subject_id),
    CONSTRAINT fk_cs_class   FOREIGN KEY (class_id)   REFERENCES classes  (id),
    CONSTRAINT fk_cs_subject FOREIGN KEY (subject_id) REFERENCES subjects (id),
    CONSTRAINT fk_cs_teacher FOREIGN KEY (teacher_id) REFERENCES users    (id)
);

-- =============================================================
-- 3. STUDENT MANAGEMENT
-- =============================================================

CREATE TABLE IF NOT EXISTS students (
    id              INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    user_id         INT UNSIGNED        NOT NULL,
    admission_no    VARCHAR(50)         NOT NULL,
    dob             DATE                NOT NULL,
    gender          ENUM('male','female','other') NOT NULL,
    class_id        SMALLINT UNSIGNED   NOT NULL,
    admission_date  DATE                NOT NULL,
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    created_by      INT UNSIGNED        DEFAULT NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_students_user   (user_id),
    UNIQUE KEY uq_students_admno  (admission_no),
    CONSTRAINT fk_students_user  FOREIGN KEY (user_id)  REFERENCES users   (id),
    CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES classes (id)
);

CREATE TABLE IF NOT EXISTS parents (
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    user_id     INT UNSIGNED    NOT NULL,
    occupation  VARCHAR(150)    DEFAULT NULL,
    address     TEXT            DEFAULT NULL,
    is_active   TINYINT(1)      NOT NULL DEFAULT 1,
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_parents_user (user_id),
    CONSTRAINT fk_parents_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS student_parents (
    student_id          INT UNSIGNED    NOT NULL,
    parent_id           INT UNSIGNED    NOT NULL,
    relationship_type   ENUM('father','mother','guardian') NOT NULL,
    PRIMARY KEY (student_id, parent_id),
    CONSTRAINT fk_sp_student FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
    CONSTRAINT fk_sp_parent  FOREIGN KEY (parent_id)  REFERENCES parents  (id) ON DELETE CASCADE
);

-- =============================================================
-- 4. ATTENDANCE
-- =============================================================

CREATE TABLE IF NOT EXISTS attendance (
    id          INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    student_id  INT UNSIGNED        NOT NULL,
    class_id    SMALLINT UNSIGNED   NOT NULL,
    date        DATE                NOT NULL,
    status      ENUM('present','absent','late','excused') NOT NULL,
    marked_by   INT UNSIGNED        NOT NULL,  -- FK -> users.id (teacher / admin)
    remarks     VARCHAR(255)        DEFAULT NULL,
    created_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_attendance_student_date (student_id, date),
    CONSTRAINT fk_att_student   FOREIGN KEY (student_id) REFERENCES students (id),
    CONSTRAINT fk_att_class     FOREIGN KEY (class_id)   REFERENCES classes  (id),
    CONSTRAINT fk_att_marked_by FOREIGN KEY (marked_by)  REFERENCES users    (id),
    INDEX idx_att_date       (date),
    INDEX idx_att_class_date (class_id, date)
);

-- =============================================================
-- 5. EXAMS & RESULTS
-- =============================================================

CREATE TABLE IF NOT EXISTS exams (
    id                  INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    name                VARCHAR(150)        NOT NULL,
    class_id            SMALLINT UNSIGNED   NOT NULL,
    term                VARCHAR(50)         NOT NULL,  -- e.g. "Term 1", "Midterm"
    exam_date           DATE                NOT NULL,
    academic_year_id    SMALLINT UNSIGNED   NOT NULL,
    is_active           TINYINT(1)          NOT NULL DEFAULT 1,
    created_by          INT UNSIGNED        DEFAULT NULL,
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_exams_class FOREIGN KEY (class_id)         REFERENCES classes        (id),
    CONSTRAINT fk_exams_year  FOREIGN KEY (academic_year_id) REFERENCES academic_years (id),
    INDEX idx_exams_class_year (class_id, academic_year_id)
);

CREATE TABLE IF NOT EXISTS exam_results (
    id              INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    exam_id         INT UNSIGNED        NOT NULL,
    student_id      INT UNSIGNED        NOT NULL,
    subject_id      SMALLINT UNSIGNED   NOT NULL,
    marks_obtained  DECIMAL(6,2)        NOT NULL,
    max_marks       DECIMAL(6,2)        NOT NULL,
    grade           VARCHAR(5)          DEFAULT NULL,
    remarks         VARCHAR(255)        DEFAULT NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_exam_result (exam_id, student_id, subject_id),
    CONSTRAINT fk_er_exam    FOREIGN KEY (exam_id)    REFERENCES exams    (id),
    CONSTRAINT fk_er_student FOREIGN KEY (student_id) REFERENCES students (id),
    CONSTRAINT fk_er_subject FOREIGN KEY (subject_id) REFERENCES subjects (id),
    INDEX idx_er_student (student_id)
);

-- =============================================================
-- 6. FEES & PAYMENTS
-- =============================================================

CREATE TABLE IF NOT EXISTS fee_structures (
    id                  INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    class_id            SMALLINT UNSIGNED   NOT NULL,
    academic_year_id    SMALLINT UNSIGNED   NOT NULL,
    fee_type            VARCHAR(100)        NOT NULL,  -- e.g. "Tuition", "Transport"
    amount              DECIMAL(10,2)       NOT NULL,
    due_date            DATE                NOT NULL,
    is_active           TINYINT(1)          NOT NULL DEFAULT 1,
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_fs_class FOREIGN KEY (class_id)         REFERENCES classes        (id),
    CONSTRAINT fk_fs_year  FOREIGN KEY (academic_year_id) REFERENCES academic_years (id),
    INDEX idx_fs_class_year (class_id, academic_year_id)
);

CREATE TABLE IF NOT EXISTS invoices (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    student_id      INT UNSIGNED    NOT NULL,
    invoice_no      VARCHAR(50)     NOT NULL,
    total_amount    DECIMAL(10,2)   NOT NULL,
    due_date        DATE            NOT NULL,
    status          ENUM('pending','partial','paid','overdue','cancelled') NOT NULL DEFAULT 'pending',
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_by      INT UNSIGNED    DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_invoices_no (invoice_no),
    CONSTRAINT fk_inv_student FOREIGN KEY (student_id) REFERENCES students (id),
    INDEX idx_inv_student (student_id),
    INDEX idx_inv_status  (status)
);

CREATE TABLE IF NOT EXISTS payments (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    invoice_id      INT UNSIGNED    NOT NULL,
    amount_paid     DECIMAL(10,2)   NOT NULL,
    payment_date    DATE            NOT NULL,
    method          ENUM('cash','card','bank_transfer','online','cheque') NOT NULL,
    reference_no    VARCHAR(100)    DEFAULT NULL,
    received_by     INT UNSIGNED    DEFAULT NULL,  -- FK -> users.id (accountant / admin)
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_pay_invoice     FOREIGN KEY (invoice_id)  REFERENCES invoices (id),
    CONSTRAINT fk_pay_received_by FOREIGN KEY (received_by) REFERENCES users    (id),
    INDEX idx_pay_invoice (invoice_id)
);

-- =============================================================
-- 7. TIMETABLE
-- =============================================================

CREATE TABLE IF NOT EXISTS rooms (
    id          SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100)        NOT NULL,
    capacity    SMALLINT UNSIGNED   NOT NULL DEFAULT 30,
    is_active   TINYINT(1)          NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_rooms_name (name)
);

CREATE TABLE IF NOT EXISTS time_slots (
    id          SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    day_of_week TINYINT UNSIGNED    NOT NULL,  -- 1=Monday … 7=Sunday
    start_time  TIME                NOT NULL,
    end_time    TIME                NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_time_slots (day_of_week, start_time, end_time)
);

CREATE TABLE IF NOT EXISTS timetables (
    id              INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    class_id        SMALLINT UNSIGNED   NOT NULL,
    subject_id      SMALLINT UNSIGNED   NOT NULL,
    teacher_id      INT UNSIGNED        NOT NULL,
    room_id         SMALLINT UNSIGNED   DEFAULT NULL,
    time_slot_id    SMALLINT UNSIGNED   NOT NULL,
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_timetable_class_slot   (class_id,   time_slot_id),
    UNIQUE KEY uq_timetable_teacher_slot (teacher_id, time_slot_id),
    UNIQUE KEY uq_timetable_room_slot    (room_id,    time_slot_id),
    CONSTRAINT fk_tt_class    FOREIGN KEY (class_id)     REFERENCES classes     (id),
    CONSTRAINT fk_tt_subject  FOREIGN KEY (subject_id)   REFERENCES subjects    (id),
    CONSTRAINT fk_tt_teacher  FOREIGN KEY (teacher_id)   REFERENCES users       (id),
    CONSTRAINT fk_tt_room     FOREIGN KEY (room_id)      REFERENCES rooms       (id),
    CONSTRAINT fk_tt_slot     FOREIGN KEY (time_slot_id) REFERENCES time_slots  (id)
);

-- =============================================================
-- 8. LIBRARY
-- =============================================================

CREATE TABLE IF NOT EXISTS books (
    id                  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    isbn                VARCHAR(20)     DEFAULT NULL,
    title               VARCHAR(255)    NOT NULL,
    author              VARCHAR(255)    DEFAULT NULL,
    category            VARCHAR(100)    DEFAULT NULL,
    copies_total        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    copies_available    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    is_active           TINYINT(1)      NOT NULL DEFAULT 1,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_books_isbn (isbn),
    INDEX idx_books_title (title)
);

CREATE TABLE IF NOT EXISTS book_issues (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    book_id         INT UNSIGNED    NOT NULL,
    student_id      INT UNSIGNED    NOT NULL,
    issued_by       INT UNSIGNED    DEFAULT NULL,  -- FK -> users.id (librarian / admin)
    issue_date      DATE            NOT NULL,
    due_date        DATE            NOT NULL,
    return_date     DATE            DEFAULT NULL,
    fine_amount     DECIMAL(8,2)    NOT NULL DEFAULT 0.00,
    status          ENUM('issued','returned','overdue') NOT NULL DEFAULT 'issued',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_bi_book      FOREIGN KEY (book_id)    REFERENCES books    (id),
    CONSTRAINT fk_bi_student   FOREIGN KEY (student_id) REFERENCES students (id),
    CONSTRAINT fk_bi_issued_by FOREIGN KEY (issued_by)  REFERENCES users    (id),
    INDEX idx_bi_student (student_id),
    INDEX idx_bi_status  (status)
);

-- =============================================================
-- 9. TRANSPORT
-- =============================================================

CREATE TABLE IF NOT EXISTS routes (
    id          SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    name        VARCHAR(150)        NOT NULL,
    vehicle_no  VARCHAR(30)         NOT NULL,
    driver_name VARCHAR(150)        DEFAULT NULL,
    is_active   TINYINT(1)          NOT NULL DEFAULT 1,
    created_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_routes_vehicle (vehicle_no)
);

CREATE TABLE IF NOT EXISTS student_transport (
    id          INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    student_id  INT UNSIGNED        NOT NULL,
    route_id    SMALLINT UNSIGNED   NOT NULL,
    stop_name   VARCHAR(150)        NOT NULL,
    fee_amount  DECIMAL(8,2)        NOT NULL DEFAULT 0.00,
    is_active   TINYINT(1)          NOT NULL DEFAULT 1,
    created_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_st_student_route (student_id, route_id),
    CONSTRAINT fk_st_student FOREIGN KEY (student_id) REFERENCES students (id),
    CONSTRAINT fk_st_route   FOREIGN KEY (route_id)   REFERENCES routes   (id)
);

-- =============================================================

SET FOREIGN_KEY_CHECKS = 1;
