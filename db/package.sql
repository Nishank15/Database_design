-- ============================================================================
-- ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM (PL/SQL PACKAGE SPEC & BODY)
-- Package Name: MESS_OPS_PKG
-- Course Project: B.Tech CSE • DBMS Full-Stack Portal
-- Developer: NISHANK CHHIPA (Reg No: 25BCE1642)
-- Architecture: Stored Procedures, Explicit Cursors, Cursor FOR Loops, MERGE
-- ============================================================================

CREATE OR REPLACE PACKAGE mess_ops_pkg AS

    -- 1. Student Registration & Onboarding
    PROCEDURE register_student (
        p_student_id      IN  VARCHAR2,
        p_name            IN  VARCHAR2,
        p_email           IN  VARCHAR2,
        p_phone           IN  VARCHAR2,
        p_block_id        IN  VARCHAR2,
        p_room_no         IN  VARCHAR2,
        p_mess_type       IN  VARCHAR2,
        p_initial_balance IN  NUMBER,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    );

    -- 2. Turnstile POS Real-Time Swipe Execution
    PROCEDURE record_turnstile_swipe (
        p_student_id      IN  VARCHAR2,
        p_category_id     IN  VARCHAR2,
        p_swipe_date      IN  DATE,
        p_turnstile_id    IN  VARCHAR2 DEFAULT 'TURNSTILE-GATE-01',
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    );

    -- 3. Monthly Billing Engine via Explicit Cursors & MERGE
    PROCEDURE calculate_monthly_billing (
        p_student_id      IN  VARCHAR2,
        p_month           IN  NUMBER,
        p_year            IN  NUMBER,
        o_total_swipes    OUT NUMBER,
        o_gross_amount    OUT NUMBER,
        o_rebate_days     OUT NUMBER,
        o_rebate_credit   OUT NUMBER,
        o_net_payable     OUT NUMBER,
        o_message         OUT VARCHAR2
    );

    -- 4. Rebate Leave Submission
    PROCEDURE apply_rebate (
        p_student_id      IN  VARCHAR2,
        p_from_date       IN  DATE,
        p_to_date         IN  DATE,
        p_reason          IN  VARCHAR2,
        o_rebate_id       OUT NUMBER,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    );

    -- 5. Rebate Review & Approval Workflow
    PROCEDURE process_rebate_action (
        p_rebate_id       IN  NUMBER,
        p_action          IN  VARCHAR2, -- 'APPROVE', 'REJECT', 'REVOKE'
        p_admin_user      IN  VARCHAR2,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    );

    -- 6. Demo Suite Reset (Clean Viva Walkthroughs)
    PROCEDURE reset_demo_swipes (
        p_student_id      IN  VARCHAR2 DEFAULT NULL,
        o_message         OUT VARCHAR2
    );

    -- 7. Wallet Top-Up / Add Funds
    PROCEDURE top_up_wallet (
        p_student_id      IN  VARCHAR2,
        p_amount          IN  NUMBER,
        p_source          IN  VARCHAR2 DEFAULT 'ADMIN',
        o_status          OUT VARCHAR2,
        o_new_balance     OUT NUMBER,
        o_message         OUT VARCHAR2
    );

    -- 8. Edit / Update Student Information
    PROCEDURE update_student (
        p_student_id      IN  VARCHAR2,
        p_name            IN  VARCHAR2,
        p_block_id        IN  VARCHAR2,
        p_room_no         IN  VARCHAR2,
        p_mess_type       IN  VARCHAR2,
        p_status          IN  VARCHAR2,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    );

    -- 9. Deregister / Delete Student (Cascading Cleanup)
    PROCEDURE deregister_student (
        p_student_id      IN  VARCHAR2,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    );

END mess_ops_pkg;
/

-- ============================================================================
-- PACKAGE BODY IMPLEMENTATION
-- ============================================================================
CREATE OR REPLACE PACKAGE BODY mess_ops_pkg AS

    -- ------------------------------------------------------------------------
    -- 1. REGISTER STUDENT
    -- ------------------------------------------------------------------------
    PROCEDURE register_student (
        p_student_id      IN  VARCHAR2,
        p_name            IN  VARCHAR2,
        p_email           IN  VARCHAR2,
        p_phone           IN  VARCHAR2,
        p_block_id        IN  VARCHAR2,
        p_room_no         IN  VARCHAR2,
        p_mess_type       IN  VARCHAR2,
        p_initial_balance IN  NUMBER,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    ) IS
        v_existing NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_existing FROM students WHERE student_id = p_student_id;
        IF v_existing > 0 THEN
            o_status := 'ERROR';
            o_message := 'Student ID [' || p_student_id || '] is already registered in boarder directory.';
            RETURN;
        END IF;

        -- Insert Student Record
        INSERT INTO students (
            student_id, name, email, phone, block_id, room_number, 
            mess_type, wallet_balance, status, created_at
        ) VALUES (
            p_student_id, p_name, p_email, p_phone, p_block_id, p_room_no,
            NVL(p_mess_type, 'VEG'), NVL(p_initial_balance, 0), 'ACTIVE', CURRENT_TIMESTAMP
        );

        -- Create Student Login Account in RBAC table
        INSERT INTO users_auth (
            username, password_hash, role, student_id, display_name, is_active
        ) VALUES (
            p_student_id, 'student123', 'STUDENT', p_student_id, p_name, 1
        );

        -- Audit Trail
        INSERT INTO audit_log (
            action_type, entity_name, entity_id, new_value, performed_by
        ) VALUES (
            'STUDENT_ENROLLED', 'STUDENTS', p_student_id,
            'Name=' || p_name || '; Block=' || p_block_id || '; Room=' || p_room_no,
            'WARDEN_PORTAL'
        );

        COMMIT;
        o_status := 'SUCCESS';
        o_message := 'Boarder [' || p_name || ' (' || p_student_id || ')] successfully enrolled.';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'ERROR';
            o_message := 'Registration failed: ' || SQLERRM;
    END register_student;


    -- ------------------------------------------------------------------------
    -- 2. RECORD TURNSTILE SWIPE
    -- ------------------------------------------------------------------------
    PROCEDURE record_turnstile_swipe (
        p_student_id      IN  VARCHAR2,
        p_category_id     IN  VARCHAR2,
        p_swipe_date      IN  DATE,
        p_turnstile_id    IN  VARCHAR2 DEFAULT 'TURNSTILE-GATE-01',
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    ) IS
        v_student_status VARCHAR2(15);
        v_balance        NUMBER(10,2);
        v_rate           NUMBER(6,2);
        v_cat_name       VARCHAR2(30);
    BEGIN
        -- 1. Validate Student Existence and Active Status
        BEGIN
            SELECT status, wallet_balance
            INTO v_student_status, v_balance
            FROM students
            WHERE student_id = p_student_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_status := 'DENIED';
                o_message := 'ACCESS DENIED: Student ID [' || p_student_id || '] not found in registry.';
                RETURN;
        END;

        IF v_student_status != 'ACTIVE' THEN
            o_status := 'DENIED';
            o_message := 'ACCESS DENIED: Student account status is ' || v_student_status || '.';
            RETURN;
        END IF;

        -- 2. Fetch Meal Category Rate
        BEGIN
            SELECT category_name, default_rate
            INTO v_cat_name, v_rate
            FROM meal_categories
            WHERE category_id = p_category_id AND is_active = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_status := 'DENIED';
                o_message := 'INVALID SLOT: Category [' || p_category_id || '] is inactive or invalid.';
                RETURN;
        END;

        -- 3. Check Wallet Balance Threshold
        IF v_balance < v_rate THEN
            o_status := 'DENIED';
            o_message := 'INSUFFICIENT BALANCE: Current balance ₹' || TO_CHAR(v_balance, '99990.99') || 
                         ' is lower than meal rate ₹' || TO_CHAR(v_rate, '99990.99') || '.';
            RETURN;
        END IF;

        -- 4. Insert Meal Swipe.
        -- NOTE: trg_prevent_duplicate_swipe and trg_rebate_swipe_guard will fire HERE!
        INSERT INTO meal_swipes (
            student_id, category_id, swipe_date, swipe_time, rate_charged, turnstile_id, status
        ) VALUES (
            p_student_id, p_category_id, TRUNC(p_swipe_date), CURRENT_TIMESTAMP, v_rate, p_turnstile_id, 'ACCEPTED'
        );

        -- 5. Deduct Rate from Student Wallet (fires trg_audit_wallet_change)
        UPDATE students
        SET wallet_balance = wallet_balance - v_rate
        WHERE student_id = p_student_id;

        COMMIT;
        o_status := 'SUCCESS';
        o_message := 'ACCESS GRANTED: ' || v_cat_name || ' swipe recorded at ' || p_turnstile_id || 
                     '. Tariff ₹' || TO_CHAR(v_rate, '990.99') || ' deducted. New Balance: ₹' || 
                     TO_CHAR(v_balance - v_rate, '99990.99');

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'DENIED';
            -- Clean Oracle exception error message
            IF SQLCODE = -20001 THEN
                o_message := 'SWIPE DENIED (DUPLICATE): Already swiped for ' || v_cat_name || 
                             ' on ' || TO_CHAR(p_swipe_date, 'YYYY-MM-DD') || '.';
            ELSIF SQLCODE = -20002 THEN
                o_message := 'SWIPE DENIED (REBATE): Student is on APPROVED mess leave on ' || 
                             TO_CHAR(p_swipe_date, 'YYYY-MM-DD') || '. Swiping violates rebate policy.';
            ELSE
                o_message := 'EXECUTION FAILED: ' || SQLERRM;
            END IF;
    END record_turnstile_swipe;


    -- ------------------------------------------------------------------------
    -- 3. CALCULATE MONTHLY BILLING (EXPLICIT CURSOR ENGINE)
    -- ------------------------------------------------------------------------
    PROCEDURE calculate_monthly_billing (
        p_student_id      IN  VARCHAR2,
        p_month           IN  NUMBER,
        p_year            IN  NUMBER,
        o_total_swipes    OUT NUMBER,
        o_gross_amount    OUT NUMBER,
        o_rebate_days     OUT NUMBER,
        o_rebate_credit   OUT NUMBER,
        o_net_payable     OUT NUMBER,
        o_message         OUT VARCHAR2
    ) IS
        -- Explicit Cursor 1: Aggregated Meal Swipes
        CURSOR c_swipes IS
            SELECT category_id, rate_charged, swipe_date
            FROM meal_swipes
            WHERE student_id = p_student_id
              AND EXTRACT(MONTH FROM swipe_date) = p_month
              AND EXTRACT(YEAR FROM swipe_date) = p_year
              AND status = 'ACCEPTED'
            ORDER BY swipe_date ASC;

        -- Explicit Cursor 2: Overlapping Approved Rebates
        CURSOR c_rebates IS
            SELECT rebate_id, from_date, to_date
            FROM rebate_requests
            WHERE student_id = p_student_id
              AND status = 'APPROVED'
              AND (
                    (EXTRACT(MONTH FROM from_date) = p_month AND EXTRACT(YEAR FROM from_date) = p_year)
                    OR 
                    (EXTRACT(MONTH FROM to_date) = p_month AND EXTRACT(YEAR FROM to_date) = p_year)
                  );

        v_swipe_rec     c_swipes%ROWTYPE;
        v_total_swipes  NUMBER := 0;
        v_gross_amount  NUMBER(10,2) := 0.00;
        v_rebate_days   NUMBER := 0;
        v_rebate_credit NUMBER(10,2) := 0.00;
        v_net_payable   NUMBER(10,2) := 0.00;
        c_daily_rebate_allowance CONSTANT NUMBER(6,2) := 180.00; -- Daily fixed rebate credit rate
    BEGIN
        -- Step A: Process Swipe Cursor
        OPEN c_swipes;
        LOOP
            FETCH c_swipes INTO v_swipe_rec;
            EXIT WHEN c_swipes%NOTFOUND;
            v_total_swipes := v_total_swipes + 1;
            v_gross_amount := v_gross_amount + v_swipe_rec.rate_charged;
        END LOOP;
        CLOSE c_swipes;

        -- Step B: Process Rebate Cursor (Cursor FOR loop)
        FOR r IN c_rebates LOOP
            -- Calculate days falling within the requested month
            DECLARE
                v_start_month DATE := TO_DATE(p_year || '-' || LPAD(p_month, 2, '0') || '-01', 'YYYY-MM-DD');
                v_end_month   DATE := LAST_DAY(v_start_month);
                v_eff_from    DATE := GREATEST(r.from_date, v_start_month);
                v_eff_to      DATE := LEAST(r.to_date, v_end_month);
                v_days        NUMBER := 0;
            BEGIN
                IF v_eff_to >= v_eff_from THEN
                    v_days := (v_eff_to - v_eff_from + 1);
                    v_rebate_days := v_rebate_days + v_days;
                END IF;
            END;
        END LOOP;

        v_rebate_credit := v_rebate_days * c_daily_rebate_allowance;
        v_net_payable   := GREATEST(0.00, v_gross_amount - v_rebate_credit);

        -- Step C: Atomic MERGE INTO monthly_bills
        MERGE INTO monthly_bills mb
        USING (
            SELECT p_student_id AS s_id, p_month AS b_month, p_year AS b_year FROM DUAL
        ) src
        ON (mb.student_id = src.s_id AND mb.billing_month = src.b_month AND mb.billing_year = src.b_year)
        WHEN MATCHED THEN
            UPDATE SET 
                total_swipes   = v_total_swipes,
                gross_amount   = v_gross_amount,
                rebate_days    = v_rebate_days,
                rebate_credit  = v_rebate_credit,
                net_payable    = v_net_payable,
                generated_at   = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (
                student_id, billing_month, billing_year, total_swipes,
                gross_amount, rebate_days, rebate_credit, net_payable,
                payment_status, generated_at
            ) VALUES (
                p_student_id, p_month, p_year, v_total_swipes,
                v_gross_amount, v_rebate_days, v_rebate_credit, v_net_payable,
                'PENDING', CURRENT_TIMESTAMP
            );

        -- Step D: Audit
        INSERT INTO audit_log (
            action_type, entity_name, entity_id, new_value, performed_by
        ) VALUES (
            'BILLING_CALCULATED', 'MONTHLY_BILLS', p_student_id,
            'Month=' || p_month || '/' || p_year || '; Gross=₹' || v_gross_amount || 
            '; RebateDays=' || v_rebate_days || '; NetPayable=₹' || v_net_payable,
            'BILLING_ENGINE'
        );

        COMMIT;

        -- Return output values
        o_total_swipes  := v_total_swipes;
        o_gross_amount  := v_gross_amount;
        o_rebate_days   := v_rebate_days;
        o_rebate_credit := v_rebate_credit;
        o_net_payable   := v_net_payable;
        o_message := 'Billing ledger reconciled for ' || TO_CHAR(TO_DATE(p_month, 'MM'), 'Month') || 
                     ' ' || p_year || '. Net Payable: ₹' || TO_CHAR(v_net_payable, '99990.99');

    EXCEPTION
        WHEN OTHERS THEN
            IF c_swipes%ISOPEN THEN CLOSE c_swipes; END IF;
            ROLLBACK;
            o_total_swipes  := 0;
            o_gross_amount  := 0;
            o_rebate_days   := 0;
            o_rebate_credit := 0;
            o_net_payable   := 0;
            o_message := 'Billing failed: ' || SQLERRM;
    END calculate_monthly_billing;


    -- ------------------------------------------------------------------------
    -- 4. APPLY REBATE
    -- ------------------------------------------------------------------------
    PROCEDURE apply_rebate (
        p_student_id      IN  VARCHAR2,
        p_from_date       IN  DATE,
        p_to_date         IN  DATE,
        p_reason          IN  VARCHAR2,
        o_rebate_id       OUT NUMBER,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    ) IS
        v_overlap NUMBER;
    BEGIN
        IF p_to_date < p_from_date THEN
            o_status := 'ERROR';
            o_message := 'INVALID DATES: End date cannot precede start date.';
            RETURN;
        END IF;

        -- Check overlap with existing approved or pending rebate
        SELECT COUNT(*)
        INTO v_overlap
        FROM rebate_requests
        WHERE student_id = p_student_id
          AND status IN ('APPROVED', 'PENDING')
          AND NOT (p_to_date < from_date OR p_from_date > to_date);

        IF v_overlap > 0 THEN
            o_status := 'ERROR';
            o_message := 'CONFLICT: Rebate request overlaps with an existing application.';
            RETURN;
        END IF;

        INSERT INTO rebate_requests (
            student_id, from_date, to_date, reason, status, applied_at
        ) VALUES (
            p_student_id, TRUNC(p_from_date), TRUNC(p_to_date), p_reason, 'PENDING', CURRENT_TIMESTAMP
        ) RETURNING rebate_id INTO o_rebate_id;

        INSERT INTO audit_log (
            action_type, entity_name, entity_id, new_value, performed_by
        ) VALUES (
            'REBATE_APPLIED', 'REBATE_REQUESTS', TO_CHAR(o_rebate_id),
            'Student=' || p_student_id || '; Dates=' || TO_CHAR(p_from_date, 'YYYY-MM-DD') || 
            ' to ' || TO_CHAR(p_to_date, 'YYYY-MM-DD'),
            p_student_id
        );

        COMMIT;
        o_status := 'SUCCESS';
        o_message := 'Rebate request #' || o_rebate_id || ' filed successfully. Awaiting warden approval.';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'ERROR';
            o_message := 'Failed to apply rebate: ' || SQLERRM;
    END apply_rebate;


    -- ------------------------------------------------------------------------
    -- 5. PROCESS REBATE ACTION
    -- ------------------------------------------------------------------------
    PROCEDURE process_rebate_action (
        p_rebate_id       IN  NUMBER,
        p_action          IN  VARCHAR2,
        p_admin_user      IN  VARCHAR2,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    ) IS
        v_curr_status VARCHAR2(20);
        v_student_id  VARCHAR2(20);
    BEGIN
        SELECT status, student_id
        INTO v_curr_status, v_student_id
        FROM rebate_requests
        WHERE rebate_id = p_rebate_id;

        IF p_action = 'APPROVE' THEN
            UPDATE rebate_requests
            SET status = 'APPROVED', reviewed_by = p_admin_user, reviewed_at = CURRENT_TIMESTAMP, remarks = 'Approved by warden'
            WHERE rebate_id = p_rebate_id;
            o_message := 'Rebate #' || p_rebate_id || ' for student ' || v_student_id || ' has been APPROVED.';
        ELSIF p_action = 'REJECT' THEN
            UPDATE rebate_requests
            SET status = 'REJECTED', reviewed_by = p_admin_user, reviewed_at = CURRENT_TIMESTAMP, remarks = 'Rejected by warden'
            WHERE rebate_id = p_rebate_id;
            o_message := 'Rebate #' || p_rebate_id || ' has been REJECTED.';
        ELSIF p_action = 'REVOKE' THEN
            UPDATE rebate_requests
            SET status = 'REVOKED', reviewed_by = p_admin_user, reviewed_at = CURRENT_TIMESTAMP, remarks = 'Revoked on student request'
            WHERE rebate_id = p_rebate_id;
            o_message := 'Rebate #' || p_rebate_id || ' has been REVOKED.';
        ELSE
            o_status := 'ERROR';
            o_message := 'Invalid action [' || p_action || ']. Expected APPROVE, REJECT, or REVOKE.';
            RETURN;
        END IF;

        INSERT INTO audit_log (
            action_type, entity_name, entity_id, old_value, new_value, performed_by
        ) VALUES (
            'REBATE_' || p_action, 'REBATE_REQUESTS', TO_CHAR(p_rebate_id),
            'PREV_STATUS=' || v_curr_status, 'NEW_STATUS=' || p_action, p_admin_user
        );

        COMMIT;
        o_status := 'SUCCESS';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_status := 'ERROR';
            o_message := 'Rebate request ID #' || p_rebate_id || ' not found.';
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'ERROR';
            o_message := 'Action failed: ' || SQLERRM;
    END process_rebate_action;


    -- ------------------------------------------------------------------------
    -- 6. RESET DEMO SWIPES (VIVA FACILITATOR)
    -- ------------------------------------------------------------------------
    PROCEDURE reset_demo_swipes (
        p_student_id      IN  VARCHAR2 DEFAULT NULL,
        o_message         OUT VARCHAR2
    ) IS
    BEGIN
        IF p_student_id IS NULL THEN
            DELETE FROM meal_swipes WHERE swipe_date = TRUNC(SYSDATE);
            o_message := 'Today''s turnstile swipe log reset for all students.';
        ELSE
            DELETE FROM meal_swipes WHERE student_id = p_student_id AND swipe_date = TRUNC(SYSDATE);
            o_message := 'Today''s turnstile swipe log reset for student ' || p_student_id || '.';
        END IF;

        INSERT INTO audit_log (
            action_type, entity_name, entity_id, new_value, performed_by
        ) VALUES (
            'DEMO_RESET', 'MEAL_SWIPES', NVL(p_student_id, 'ALL'),
            'Reset swipes for testing and viva presentation', 'WARDEN_ADMIN'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_message := 'Reset failed: ' || SQLERRM;
    END reset_demo_swipes;


    -- ------------------------------------------------------------------------
    -- 7. TOP-UP WALLET / ADD FUNDS
    -- ------------------------------------------------------------------------
    PROCEDURE top_up_wallet (
        p_student_id      IN  VARCHAR2,
        p_amount          IN  NUMBER,
        p_source          IN  VARCHAR2 DEFAULT 'ADMIN',
        o_status          OUT VARCHAR2,
        o_new_balance     OUT NUMBER,
        o_message         OUT VARCHAR2
    ) IS
        v_current_bal NUMBER(10,2);
    BEGIN
        IF p_amount <= 0 THEN
            o_status := 'ERROR';
            o_new_balance := 0;
            o_message := 'INVALID AMOUNT: Top-up amount must be strictly greater than 0.';
            RETURN;
        END IF;

        BEGIN
            SELECT wallet_balance
            INTO v_current_bal
            FROM students
            WHERE student_id = p_student_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_status := 'ERROR';
                o_new_balance := 0;
                o_message := 'Student ID [' || p_student_id || '] not found in registry.';
                RETURN;
        END;

        -- Update balance (trg_audit_wallet_change automatically fires here)
        UPDATE students
        SET wallet_balance = wallet_balance + p_amount
        WHERE student_id = p_student_id;

        o_new_balance := v_current_bal + p_amount;

        -- Explicit top-up audit record
        INSERT INTO audit_log (
            action_type, entity_name, entity_id, old_value, new_value, performed_by
        ) VALUES (
            'WALLET_TOP_UP', 'STUDENTS', p_student_id,
            'PREV_BALANCE=₹' || TO_CHAR(v_current_bal, '999990.99'),
            'CREDIT=₹' || TO_CHAR(p_amount, '999990.99') || '; NEW_BALANCE=₹' || TO_CHAR(o_new_balance, '999990.99') || '; SOURCE=' || p_source,
            p_source
        );

        COMMIT;
        o_status := 'SUCCESS';
        o_message := 'Top-up successful! ₹' || TO_CHAR(p_amount, '999990.99') || ' added to student [' || p_student_id || ']. New Balance: ₹' || TO_CHAR(o_new_balance, '999990.99');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'ERROR';
            o_new_balance := v_current_bal;
            o_message := 'Wallet top-up failed: ' || SQLERRM;
    END top_up_wallet;


    -- ------------------------------------------------------------------------
    -- 8. EDIT / UPDATE STUDENT INFORMATION
    -- ------------------------------------------------------------------------
    PROCEDURE update_student (
        p_student_id      IN  VARCHAR2,
        p_name            IN  VARCHAR2,
        p_block_id        IN  VARCHAR2,
        p_room_no         IN  VARCHAR2,
        p_mess_type       IN  VARCHAR2,
        p_status          IN  VARCHAR2,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    ) IS
        v_existing NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_existing FROM students WHERE student_id = p_student_id;
        IF v_existing = 0 THEN
            o_status := 'ERROR';
            o_message := 'Student ID [' || p_student_id || '] not found.';
            RETURN;
        END IF;

        -- Update student core record
        UPDATE students
        SET name = p_name,
            block_id = p_block_id,
            room_number = p_room_no,
            mess_type = NVL(p_mess_type, 'VEG'),
            status = NVL(p_status, 'ACTIVE')
        WHERE student_id = p_student_id;

        -- Update auth display name
        UPDATE users_auth
        SET display_name = p_name
        WHERE student_id = p_student_id;

        INSERT INTO audit_log (
            action_type, entity_name, entity_id, new_value, performed_by
        ) VALUES (
            'STUDENT_UPDATED', 'STUDENTS', p_student_id,
            'Name=' || p_name || '; Block=' || p_block_id || '; Room=' || p_room_no || '; Mess=' || p_mess_type || '; Status=' || p_status,
            'WARDEN_ADMIN'
        );

        COMMIT;
        o_status := 'SUCCESS';
        o_message := 'Student [' || p_student_id || '] profile successfully updated.';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'ERROR';
            o_message := 'Update failed: ' || SQLERRM;
    END update_student;


    -- ------------------------------------------------------------------------
    -- 9. DEREGISTER / DELETE STUDENT (CASCADING CLEANUP)
    -- ------------------------------------------------------------------------
    PROCEDURE deregister_student (
        p_student_id      IN  VARCHAR2,
        o_status          OUT VARCHAR2,
        o_message         OUT VARCHAR2
    ) IS
        v_name VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT name INTO v_name FROM students WHERE student_id = p_student_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                o_status := 'ERROR';
                o_message := 'Student ID [' || p_student_id || '] not found.';
                RETURN;
        END;

        -- Cascading deletion of dependent transactional records
        DELETE FROM meal_swipes WHERE student_id = p_student_id;
        DELETE FROM rebate_requests WHERE student_id = p_student_id;
        DELETE FROM monthly_bills WHERE student_id = p_student_id;
        DELETE FROM users_auth WHERE student_id = p_student_id;
        DELETE FROM students WHERE student_id = p_student_id;

        INSERT INTO audit_log (
            action_type, entity_name, entity_id, new_value, performed_by
        ) VALUES (
            'STUDENT_DEREGISTERED', 'STUDENTS', p_student_id,
            'Student [' || v_name || ' (' || p_student_id || ')] completely deregistered with cascading logs cleanup',
            'WARDEN_ADMIN'
        );

        COMMIT;
        o_status := 'SUCCESS';
        o_message := 'Boarder [' || v_name || ' (' || p_student_id || ')] has been deleted and deregistered.';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            o_status := 'ERROR';
            o_message := 'Deregistration failed: ' || SQLERRM;
    END deregister_student;

END mess_ops_pkg;
/

PROMPT =========================================================================
PROMPT PL/SQL Package MESS_OPS_PKG Compiled and Ready!
PROMPT =========================================================================
