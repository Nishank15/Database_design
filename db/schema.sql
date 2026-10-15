-- ============================================================================
-- ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM (ORACLE PL/SQL & SQL*PLUS DDL)
-- Course Project: B.Tech CSE • DBMS Full-Stack Portal
-- Developer: NISHANK CHHIPA (Reg No: 25BCE1642)
-- Relational Model: Normalized 3NF Suite with Strict Integrity Constraints
-- ============================================================================

SET SERVEROUTPUT ON;
WHENEVER SQLERROR CONTINUE;

-- ----------------------------------------------------------------------------
-- 1. DROP EXISTING OBJECTS (CLEAN SLATE SETUP)
-- ----------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_student_mess_ledger';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE audit_log CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE monthly_bills CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE meal_swipes CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE rebate_requests CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE daily_menus CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE meal_categories CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE users_auth CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE students CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE hostel_blocks CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- ----------------------------------------------------------------------------
-- 2. DDL: 3NF NORMALIZED RELATIONAL TABLES
-- ----------------------------------------------------------------------------

-- Table 1: HOSTEL_BLOCKS (Residential Units)
CREATE TABLE hostel_blocks (
    block_id         VARCHAR2(10)     NOT NULL,
    block_name       VARCHAR2(50)     NOT NULL,
    total_capacity   NUMBER(5)        DEFAULT 200 NOT NULL,
    warden_incharge  VARCHAR2(100)    NOT NULL,
    contact_no       VARCHAR2(20)     NOT NULL,
    CONSTRAINT pk_hostel_blocks PRIMARY KEY (block_id),
    CONSTRAINT chk_block_capacity CHECK (total_capacity > 0)
);

-- Table 2: STUDENTS (Boarder Registry)
CREATE TABLE students (
    student_id       VARCHAR2(20)     NOT NULL,
    name             VARCHAR2(100)    NOT NULL,
    email            VARCHAR2(100)    NOT NULL,
    phone            VARCHAR2(20)     NOT NULL,
    block_id         VARCHAR2(10)     NOT NULL,
    room_number      VARCHAR2(15)     NOT NULL,
    mess_type        VARCHAR2(20)     DEFAULT 'VEG' NOT NULL,
    wallet_balance   NUMBER(10,2)     DEFAULT 0.00 NOT NULL,
    status           VARCHAR2(15)     DEFAULT 'ACTIVE' NOT NULL,
    created_at       TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_students PRIMARY KEY (student_id),
    CONSTRAINT fk_student_block FOREIGN KEY (block_id) 
        REFERENCES hostel_blocks(block_id) ON DELETE CASCADE,
    CONSTRAINT uq_student_email UNIQUE (email),
    CONSTRAINT chk_student_mess_type CHECK (mess_type IN ('VEG', 'NON_VEG', 'SPECIAL')),
    CONSTRAINT chk_student_balance CHECK (wallet_balance >= 0),
    CONSTRAINT chk_student_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);

-- Table 3: USERS_AUTH (Role-Based Access Control Credentials)
CREATE TABLE users_auth (
    user_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    username         VARCHAR2(50)     NOT NULL,
    password_hash    VARCHAR2(255)    NOT NULL,
    role             VARCHAR2(20)     NOT NULL,
    student_id       VARCHAR2(20),
    display_name     VARCHAR2(100)    NOT NULL,
    is_active        NUMBER(1)        DEFAULT 1 NOT NULL,
    created_at       TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_users_auth PRIMARY KEY (user_id),
    CONSTRAINT uq_auth_username UNIQUE (username),
    CONSTRAINT fk_auth_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT chk_auth_role CHECK (role IN ('ADMIN', 'STUDENT')),
    CONSTRAINT chk_auth_active CHECK (is_active IN (0, 1))
);

-- Table 4: MEAL_CATEGORIES (Slot Metadata & Standard Tariff)
CREATE TABLE meal_categories (
    category_id      VARCHAR2(10)     NOT NULL,
    category_name    VARCHAR2(30)     NOT NULL,
    start_time       VARCHAR2(8)      NOT NULL, -- Format HH24:MI
    end_time         VARCHAR2(8)      NOT NULL,
    default_rate     NUMBER(6,2)      NOT NULL,
    is_active        NUMBER(1)        DEFAULT 1 NOT NULL,
    CONSTRAINT pk_meal_categories PRIMARY KEY (category_id),
    CONSTRAINT chk_meal_cat_name CHECK (category_name IN ('BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER')),
    CONSTRAINT chk_meal_rate CHECK (default_rate >= 0),
    CONSTRAINT chk_cat_active CHECK (is_active IN (0, 1))
);

-- Table 5: DAILY_MENUS (Catering Schedule)
CREATE TABLE daily_menus (
    menu_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    menu_date        DATE             NOT NULL,
    category_id      VARCHAR2(10)     NOT NULL,
    mess_type        VARCHAR2(20)     DEFAULT 'VEG' NOT NULL,
    menu_items       VARCHAR2(500)    NOT NULL,
    special_note     VARCHAR2(200),
    CONSTRAINT pk_daily_menus PRIMARY KEY (menu_id),
    CONSTRAINT fk_menu_category FOREIGN KEY (category_id)
        REFERENCES meal_categories(category_id) ON DELETE CASCADE,
    CONSTRAINT chk_menu_mess_type CHECK (mess_type IN ('VEG', 'NON_VEG', 'SPECIAL')),
    CONSTRAINT uq_daily_menu UNIQUE (menu_date, category_id, mess_type)
);

-- Table 6: REBATE_REQUESTS (Leave & Mess Rebate Governance)
CREATE TABLE rebate_requests (
    rebate_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    student_id       VARCHAR2(20)     NOT NULL,
    from_date        DATE             NOT NULL,
    to_date          DATE             NOT NULL,
    reason           VARCHAR2(255)    NOT NULL,
    status           VARCHAR2(20)     DEFAULT 'PENDING' NOT NULL,
    applied_at       TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_by      VARCHAR2(50),
    reviewed_at      TIMESTAMP,
    remarks          VARCHAR2(255),
    CONSTRAINT pk_rebate_requests PRIMARY KEY (rebate_id),
    CONSTRAINT fk_rebate_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT chk_rebate_dates CHECK (from_date <= to_date),
    CONSTRAINT chk_rebate_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'REVOKED'))
);

-- Table 7: MEAL_SWIPES (Access Control Turnstile Execution Log)
CREATE TABLE meal_swipes (
    swipe_id         NUMBER GENERATED ALWAYS AS IDENTITY,
    student_id       VARCHAR2(20)     NOT NULL,
    category_id      VARCHAR2(10)     NOT NULL,
    swipe_date       DATE             NOT NULL,
    swipe_time       TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    rate_charged     NUMBER(6,2)      NOT NULL,
    turnstile_id     VARCHAR2(20)     DEFAULT 'TURNSTILE-GATE-01' NOT NULL,
    status           VARCHAR2(15)     DEFAULT 'ACCEPTED' NOT NULL,
    CONSTRAINT pk_meal_swipes PRIMARY KEY (swipe_id),
    CONSTRAINT fk_swipe_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_swipe_category FOREIGN KEY (category_id)
        REFERENCES meal_categories(category_id) ON DELETE CASCADE,
    CONSTRAINT chk_swipe_rate CHECK (rate_charged >= 0),
    CONSTRAINT chk_swipe_status CHECK (status IN ('ACCEPTED', 'FLAGGED', 'BLOCKED'))
);

-- Table 8: MONTHLY_BILLS (Periodic Billing & Ledger Accounts)
CREATE TABLE monthly_bills (
    bill_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    student_id       VARCHAR2(20)     NOT NULL,
    billing_month    NUMBER(2)        NOT NULL,
    billing_year     NUMBER(4)        NOT NULL,
    total_swipes     NUMBER(5)        DEFAULT 0 NOT NULL,
    gross_amount     NUMBER(10,2)     DEFAULT 0.00 NOT NULL,
    rebate_days      NUMBER(4)        DEFAULT 0 NOT NULL,
    rebate_credit    NUMBER(10,2)     DEFAULT 0.00 NOT NULL,
    net_payable      NUMBER(10,2)     DEFAULT 0.00 NOT NULL,
    payment_status   VARCHAR2(20)     DEFAULT 'PENDING' NOT NULL,
    generated_at     TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_monthly_bills PRIMARY KEY (bill_id),
    CONSTRAINT fk_bill_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT uq_student_bill_period UNIQUE (student_id, billing_month, billing_year),
    CONSTRAINT chk_billing_month CHECK (billing_month BETWEEN 1 AND 12),
    CONSTRAINT chk_billing_year CHECK (billing_year >= 2020),
    CONSTRAINT chk_payment_status CHECK (payment_status IN ('PENDING', 'PAID', 'OVERDUE'))
);

-- Table 9: AUDIT_LOG (Enterprise Immutable System Journal)
CREATE TABLE audit_log (
    log_id           NUMBER GENERATED ALWAYS AS IDENTITY,
    action_type      VARCHAR2(50)     NOT NULL,
    entity_name      VARCHAR2(50)     NOT NULL,
    entity_id        VARCHAR2(50)     NOT NULL,
    old_value        VARCHAR2(4000),
    new_value        VARCHAR2(4000),
    performed_by     VARCHAR2(50)     DEFAULT 'SYSTEM' NOT NULL,
    logged_at        TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id)
);

-- ----------------------------------------------------------------------------
-- 3. DATE-AWARE DATABASE TRIGGERS
-- ----------------------------------------------------------------------------

-- Trigger 1: TRG_PREVENT_DUPLICATE_SWIPE
-- Prevents double-swiping for the exact same meal category on the same calendar day.
CREATE OR REPLACE TRIGGER trg_prevent_duplicate_swipe
BEFORE INSERT ON meal_swipes
FOR EACH ROW
DECLARE
    v_swipe_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_swipe_count
    FROM meal_swipes
    WHERE student_id = :NEW.student_id
      AND category_id = :NEW.category_id
      AND TRUNC(swipe_date) = TRUNC(:NEW.swipe_date)
      AND status = 'ACCEPTED';

    IF v_swipe_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'DUPLICATE SWIPE VIOLATION: Student [' || :NEW.student_id || 
            '] has already swiped for category [' || :NEW.category_id || 
            '] on date [' || TO_CHAR(:NEW.swipe_date, 'YYYY-MM-DD') || '].'
        );
    END IF;
END;
/

-- Trigger 2: TRG_REBATE_SWIPE_GUARD
-- Date-aware guard: Blocks turnstile swipe if student has an active APPROVED rebate leave covering the date.
CREATE OR REPLACE TRIGGER trg_rebate_swipe_guard
BEFORE INSERT ON meal_swipes
FOR EACH ROW
DECLARE
    v_rebate_count NUMBER;
    v_from DATE;
    v_to DATE;
BEGIN
    SELECT COUNT(*), MIN(from_date), MAX(to_date)
    INTO v_rebate_count, v_from, v_to
    FROM rebate_requests
    WHERE student_id = :NEW.student_id
      AND status = 'APPROVED'
      AND TRUNC(:NEW.swipe_date) BETWEEN TRUNC(from_date) AND TRUNC(to_date);

    IF v_rebate_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'REBATE LEAVE CONFLICT: Student [' || :NEW.student_id || 
            '] is marked on APPROVED rebate leave from [' || 
            TO_CHAR(v_from, 'YYYY-MM-DD') || '] to [' || 
            TO_CHAR(v_to, 'YYYY-MM-DD') || ']. Meal swipes are prohibited during rebate periods.'
        );
    END IF;
END;
/

-- Trigger 3: TRG_AUDIT_WALLET_CHANGE
-- Audits any modification of a student's wallet balance into the immutable audit journal.
CREATE OR REPLACE TRIGGER trg_audit_wallet_change
AFTER UPDATE OF wallet_balance ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        action_type,
        entity_name,
        entity_id,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        'WALLET_BALANCE_UPDATE',
        'STUDENTS',
        :NEW.student_id,
        'PREV_BALANCE=' || TO_CHAR(:OLD.wallet_balance, '999990.99'),
        'NEW_BALANCE=' || TO_CHAR(:NEW.wallet_balance, '999990.99'),
        NVL(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), 'TURNSTILE_OR_ADMIN')
    );
END;
/

-- ----------------------------------------------------------------------------
-- 4. RELATIONAL LEDGER VIEW (V_STUDENT_MESS_LEDGER)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_student_mess_ledger AS
SELECT 
    s.student_id,
    s.name,
    s.block_id,
    b.block_name,
    s.room_number,
    s.mess_type,
    s.wallet_balance,
    s.status AS student_status,
    COUNT(DISTINCT ms.swipe_id) AS total_swipes_count,
    NVL(SUM(ms.rate_charged), 0) AS total_swipe_expenditure,
    COUNT(DISTINCT CASE WHEN rr.status = 'APPROVED' THEN rr.rebate_id END) AS approved_rebate_count,
    NVL(SUM(CASE WHEN rr.status = 'APPROVED' THEN (rr.to_date - rr.from_date + 1) ELSE 0 END), 0) AS total_approved_rebate_days
FROM students s
JOIN hostel_blocks b ON s.block_id = b.block_id
LEFT JOIN meal_swipes ms ON s.student_id = ms.student_id AND ms.status = 'ACCEPTED'
LEFT JOIN rebate_requests rr ON s.student_id = rr.student_id
GROUP BY 
    s.student_id,
    s.name,
    s.block_id,
    b.block_name,
    s.room_number,
    s.mess_type,
    s.wallet_balance,
    s.status;

-- ----------------------------------------------------------------------------
-- 5. INITIAL SEED DATA
-- ----------------------------------------------------------------------------

-- Seed Hostel Blocks
INSERT INTO hostel_blocks (block_id, block_name, total_capacity, warden_incharge, contact_no)
VALUES ('BLK-A', 'Block A (Aryabhatta Hall)', 250, 'Dr. K. Ramanathan', '+91 98450 11021');

INSERT INTO hostel_blocks (block_id, block_name, total_capacity, warden_incharge, contact_no)
VALUES ('BLK-B', 'Block B (Bhabha Hall)', 300, 'Prof. S. Mukherjee', '+91 98450 11022');

INSERT INTO hostel_blocks (block_id, block_name, total_capacity, warden_incharge, contact_no)
VALUES ('BLK-C', 'Block C (Charaka Hall)', 200, 'Dr. M. Venkataraman', '+91 98450 11023');

INSERT INTO hostel_blocks (block_id, block_name, total_capacity, warden_incharge, contact_no)
VALUES ('BLK-D', 'Block D (Dhanvantari Hall)', 220, 'Dr. P. Deshmukh', '+91 98450 11024');

-- Seed Meal Categories (Timings & Standard Rates)
INSERT INTO meal_categories (category_id, category_name, start_time, end_time, default_rate, is_active)
VALUES ('CAT-BF', 'BREAKFAST', '07:30', '09:30', 50.00, 1);

INSERT INTO meal_categories (category_id, category_name, start_time, end_time, default_rate, is_active)
VALUES ('CAT-LN', 'LUNCH', '12:30', '14:30', 90.00, 1);

INSERT INTO meal_categories (category_id, category_name, start_time, end_time, default_rate, is_active)
VALUES ('CAT-SN', 'SNACKS', '17:00', '18:30', 35.00, 1);

INSERT INTO meal_categories (category_id, category_name, start_time, end_time, default_rate, is_active)
VALUES ('CAT-DN', 'DINNER', '19:30', '21:30', 95.00, 1);

-- Seed Students (Including Student 25BCE1642 Nishank Chhipa)
INSERT INTO students (student_id, name, email, phone, block_id, room_number, mess_type, wallet_balance, status)
VALUES ('25BCE1642', 'NISHANK CHHIPA', 'nishank.chhipa2025@vitstudent.ac.in', '+91 94140 88219', 'BLK-B', '412', 'NON_VEG', 3450.00, 'ACTIVE');

INSERT INTO students (student_id, name, email, phone, block_id, room_number, mess_type, wallet_balance, status)
VALUES ('25BCE1001', 'Aarav Sharma', 'aarav.sharma2025@vitstudent.ac.in', '+91 98765 43210', 'BLK-A', '104', 'VEG', 1850.00, 'ACTIVE');

INSERT INTO students (student_id, name, email, phone, block_id, room_number, mess_type, wallet_balance, status)
VALUES ('25BCE1089', 'Diya Iyer', 'diya.iyer2025@vitstudent.ac.in', '+91 98112 34567', 'BLK-B', '205', 'SPECIAL', 4200.00, 'ACTIVE');

INSERT INTO students (student_id, name, email, phone, block_id, room_number, mess_type, wallet_balance, status)
VALUES ('25BCE1244', 'Rohan Verma', 'rohan.verma2025@vitstudent.ac.in', '+91 97234 56789', 'BLK-C', '310', 'NON_VEG', 520.00, 'ACTIVE');

INSERT INTO students (student_id, name, email, phone, block_id, room_number, mess_type, wallet_balance, status)
VALUES ('25BCE1560', 'Ananya Patel', 'ananya.patel2025@vitstudent.ac.in', '+91 96543 21098', 'BLK-D', '118', 'VEG', 2900.00, 'ACTIVE');

INSERT INTO students (student_id, name, email, phone, block_id, room_number, mess_type, wallet_balance, status)
VALUES ('25BCE1780', 'Kabir Reddy', 'kabir.reddy2025@vitstudent.ac.in', '+91 95432 10987', 'BLK-A', '221', 'SPECIAL', 150.00, 'ACTIVE');

-- Seed RBAC Authentication Credentials
INSERT INTO users_auth (username, password_hash, role, student_id, display_name, is_active)
VALUES ('admin', 'admin123', 'ADMIN', NULL, 'Chief Mess Warden', 1);

INSERT INTO users_auth (username, password_hash, role, student_id, display_name, is_active)
VALUES ('warden_b', 'warden123', 'ADMIN', NULL, 'Bhabha Hall Warden', 1);

INSERT INTO users_auth (username, password_hash, role, student_id, display_name, is_active)
VALUES ('25BCE1642', 'student123', 'STUDENT', '25BCE1642', 'Nishank Chhipa (25BCE1642)', 1);

INSERT INTO users_auth (username, password_hash, role, student_id, display_name, is_active)
VALUES ('25BCE1001', 'student123', 'STUDENT', '25BCE1001', 'Aarav Sharma (25BCE1001)', 1);

INSERT INTO users_auth (username, password_hash, role, student_id, display_name, is_active)
VALUES ('25BCE1089', 'student123', 'STUDENT', '25BCE1089', 'Diya Iyer (25BCE1089)', 1);

-- Seed Daily Menus (Sample Today)
INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-BF', 'VEG', 'Masala Dosa, Sambar, Coconut Chutney, Fresh Fruits, Tea/Coffee', 'South Indian Special');

INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-BF', 'NON_VEG', 'Boiled Eggs, Masala Omelette, Bread Butter, Hash Browns, Tea/Coffee', 'High Protein Breakfast');

INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-LN', 'VEG', 'Paneer Butter Masala, Dal Tadka, Jeera Rice, Phulka, Boondi Raita, Gulab Jamun', 'Royal Thali');

INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-LN', 'NON_VEG', 'Hyderabadi Chicken Biryani, Mirchi Ka Salan, Raita, Boiled Egg, Phulka', 'Dum Biryani Festival');

INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-SN', 'VEG', 'Vegetable Samosa, Mint Chutney, Roasted Corn, Masala Chai', 'Evening Refreshment');

INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-DN', 'VEG', 'Kadhai Mushroom, Yellow Dal, Steamed Rice, Tandoori Roti, Salad', 'Balanced Dinner');

INSERT INTO daily_menus (menu_date, category_id, mess_type, menu_items, special_note)
VALUES (TRUNC(SYSDATE), 'CAT-DN', 'NON_VEG', 'Butter Chicken Gravy, Jeera Rice, Rumali Roti, Onion Rings', 'Chef Special Non-Veg');

-- Seed Rebate Requests (Past, Active, Future)
INSERT INTO rebate_requests (student_id, from_date, to_date, reason, status, reviewed_by, reviewed_at, remarks)
VALUES ('25BCE1001', TRUNC(SYSDATE) - 10, TRUNC(SYSDATE) - 7, 'Attending Inter-University Hackathon in Bengaluru', 'APPROVED', 'admin', SYSTIMESTAMP - 10, 'Approved on submission of official OD certificate');

INSERT INTO rebate_requests (student_id, from_date, to_date, reason, status, reviewed_by, reviewed_at, remarks)
VALUES ('25BCE1244', TRUNC(SYSDATE) - 2, TRUNC(SYSDATE) + 2, 'Medical emergency leave with home warden intimation', 'APPROVED', 'admin', SYSTIMESTAMP - 2, 'Doctor prescription verified');

INSERT INTO rebate_requests (student_id, from_date, to_date, reason, status, remarks)
VALUES ('25BCE1642', TRUNC(SYSDATE) + 3, TRUNC(SYSDATE) + 6, 'Family function in hometown (Jaipur, Rajasthan)', 'PENDING', 'Awaiting parent confirmation call');

INSERT INTO rebate_requests (student_id, from_date, to_date, reason, status, reviewed_by, reviewed_at, remarks)
VALUES ('25BCE1560', TRUNC(SYSDATE) - 15, TRUNC(SYSDATE) - 12, 'Project conference symposium paper presentation', 'APPROVED', 'admin', SYSTIMESTAMP - 15, 'Academic leave granted');

-- Seed Historical Swipes
INSERT INTO meal_swipes (student_id, category_id, swipe_date, swipe_time, rate_charged, turnstile_id, status)
VALUES ('25BCE1642', 'CAT-BF', TRUNC(SYSDATE) - 1, SYSTIMESTAMP - INTERVAL '1' DAY, 50.00, 'TURNSTILE-GATE-01', 'ACCEPTED');

INSERT INTO meal_swipes (student_id, category_id, swipe_date, swipe_time, rate_charged, turnstile_id, status)
VALUES ('25BCE1642', 'CAT-LN', TRUNC(SYSDATE) - 1, SYSTIMESTAMP - INTERVAL '1' DAY, 90.00, 'TURNSTILE-GATE-01', 'ACCEPTED');

INSERT INTO meal_swipes (student_id, category_id, swipe_date, swipe_time, rate_charged, turnstile_id, status)
VALUES ('25BCE1642', 'CAT-DN', TRUNC(SYSDATE) - 1, SYSTIMESTAMP - INTERVAL '1' DAY, 95.00, 'TURNSTILE-GATE-02', 'ACCEPTED');

INSERT INTO meal_swipes (student_id, category_id, swipe_date, swipe_time, rate_charged, turnstile_id, status)
VALUES ('25BCE1089', 'CAT-BF', TRUNC(SYSDATE), SYSTIMESTAMP - INTERVAL '1' HOUR, 50.00, 'TURNSTILE-GATE-01', 'ACCEPTED');

COMMIT;

-- Verification output
PROMPT =========================================================================
PROMPT Oracle Relational Schema Deployed Successfully for Student 25BCE1642!
PROMPT =========================================================================
SELECT table_name FROM user_tables ORDER BY table_name;
