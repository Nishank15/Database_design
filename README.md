# Enterprise Hostel Mess Management System
> **Full-Stack DBMS Portal • B.Tech CSE Semester 3**  
> **Lead Architect & Developer:** **NISHANK CHHIPA**  
> **Registration Number:** **25BCE1642**  
> **Technology Suite:** Oracle PL/SQL • SQL*Plus • Java JDBC (`ojdbc11`) • Python ODBC (`pyodbc`) • Midnight Dark Portal

---

## 1. System Overview & Architecture

The **Enterprise Hostel Mess Management System** is a production-grade full-stack portal engineered for university residential campuses. It integrates 3NF-normalized relational database architecture, date-aware stored procedures, triggers, explicit cursors, and an interactive frontend built according to the **Linear Design System (Midnight Dark Precision)**.

```
                           +----------------------------------------+
                           |  Frontend Client (HTML5 / CSS3 / JS)  |
                           |  Void #08090a • Acid Lime #e4f222 CTA  |
                           +----------------------------------------+
                                        |                 |
                   (REST JSON API)     |                 | (ODBC Query Engine)
                                        v                 v
            +------------------------------------+   +------------------------------------+
            |      Java 25 Backend Server        |   |    Python ODBC Report Generator    |
            |   (MessManagementServer.java)      |   |       (reports/odbc_audit.py)      |
            +------------------------------------+   +------------------------------------+
                                        |                             |
                                (Oracle JDBC)                  (Oracle ODBC Driver)
                                        |                             |
                                        +--------------+--------------+
                                                       |
                                                       v
                                    +-------------------------------------+
                                    |    Oracle Database 19c / 21c XE     |
                                    |  • 8 Normalized 3NF Tables          |
                                    |  • Package: MESS_OPS_PKG            |
                                    |  • Triggers: Duplicate & Rebate     |
                                    |  • Ledger View: v_student_mess_ledger|
                                    +-------------------------------------+
```

---

## 2. Developer Credits & Identification

- **Student Developer:** `NISHANK CHHIPA`
- **Registration No:** `25BCE1642`
- **Branch & Specialization:** `B.Tech Computer Science & Engineering (CSE)`
- **Subject:** `Database Management Systems (DBMS) Laboratory Project`
- **Component Deliverables:**
  - `db/schema.sql`: Oracle SQL DDL, 8 tables, 3 triggers, 1 relational view, seed data.
  - `db/package.sql`: PL/SQL package `mess_ops_pkg` with explicit cursors and `MERGE`.
  - `backend/MessManagementServer.java`: Lightweight Java HTTP server with JDBC execution.
  - `reports/odbc_audit.py`: Python ODBC reporting and ledger reconciliation script.
  - `public/index.html`, `public/style.css`, `public/app.js`: High-precision dark mode portal.

---

## 3. Database Architecture (Oracle 3NF Schema & Triggers)

### Normalized 3NF Relational Tables
1. **`hostel_blocks`**: Residential halls (`block_id` PK, `block_name`, capacity, wardens, contacts).
2. **`students`**: Boarder registry (`student_id` PK, `name`, `email`, `phone`, `block_id` FK, `room_number`, `mess_type` [VEG/NON_VEG/SPECIAL], `wallet_balance`, `status`).
3. **`users_auth`**: RBAC credentials (`user_id` PK, `username` UQ, `password_hash`, `role` [ADMIN/STUDENT], `student_id` FK).
4. **`meal_categories`**: Slot timings and tariffs (`category_id` PK, `category_name` [BREAKFAST, LUNCH, SNACKS, DINNER], timings, `default_rate`).
5. **`daily_menus`**: Caterer food schedule (`menu_id` PK, `menu_date`, `category_id` FK, `mess_type`, `menu_items`).
6. **`rebate_requests`**: Mess leave governance (`rebate_id` PK, `student_id` FK, `from_date`, `to_date`, `reason`, `status` [PENDING, APPROVED, REJECTED, REVOKED]).
7. **`meal_swipes`**: Turnstile access journal (`swipe_id` PK, `student_id` FK, `category_id` FK, `swipe_date`, `swipe_time`, `rate_charged`, `turnstile_id`, `status`).
8. **`monthly_bills`**: Periodic accounts (`bill_id` PK, `student_id` FK, `billing_month`, `billing_year`, `total_swipes`, `gross_amount`, `rebate_days`, `rebate_credit`, `net_payable`, `payment_status`).
9. **`audit_log`**: Immutable system audit trail (`log_id` PK, `action_type`, `entity_name`, `entity_id`, delta fields, `performed_by`, `logged_at`).

### Date-Aware PL/SQL Triggers
- **`trg_prevent_duplicate_swipe`**: Fires `BEFORE INSERT ON meal_swipes`. Queries existing accepted swipes for the same student, meal category, and calendar date (`TRUNC(swipe_date)`). If found, raises Oracle Error `-20001: DUPLICATE SWIPE VIOLATION`.
- **`trg_rebate_swipe_guard`**: Fires `BEFORE INSERT ON meal_swipes`. Verifies if `TRUNC(swipe_date)` falls within any `APPROVED` rebate interval (`from_date` to `to_date`). If active, raises Oracle Error `-20002: REBATE LEAVE CONFLICT`.
- **`trg_audit_wallet_change`**: Fires `AFTER UPDATE OF wallet_balance ON students`. Automatically logs previous balance, new balance, and client identifier into `audit_log`.

### PL/SQL Business Logic Package (`mess_ops_pkg`)
- **`register_student`**: Enrolls a student, creates their RBAC portal account, initializes float balance, and audits the transaction.
- **`record_turnstile_swipe`**: Validates student active status, verifies sufficient float balance, executes insertion to trigger constraints, deducts tariff, and commits.
- **`calculate_monthly_billing`**: Uses explicit cursors (`c_swipes` and `c_rebates`) with cursor `FOR` loops to calculate total swipes, gross charges, overlapping rebate credit (at ₹180.00/day), and performs an atomic `MERGE INTO monthly_bills`.
- **`apply_rebate` & `process_rebate_action`**: Handles student leave requests, validation against overlapping dates, and warden approvals/rejections/revocations.
- **`reset_demo_swipes`**: Clears swipes for the active date to facilitate repeatable, clean viva walkthroughs.
- **`top_up_wallet`**: Deposits funds into student float balance (`POST /api/students/add-funds`), records transaction in `audit_log`, and triggers balance updates.
- **`update_student`**: Modifies boarder information (Name, Block, Room, Mess Plan, Status) via `POST /api/students/update`.
- **`deregister_student`**: Deletes a boarder with cascading cleanup across swipes, rebates, bills, and auth records via `POST /api/students/delete`.

---

## 4. How to Run the Project

### A. Deploy Oracle Relational Schema & Package
Run in Oracle SQL*Plus or SQL Developer:
```bash
sqlplus c##mess_admin/oracle123@localhost:1521/ORCLCDB @db/schema.sql
sqlplus c##mess_admin/oracle123@localhost:1521/ORCLCDB @db/package.sql
```

### B. Launch Java Backend Server
```bash
# Compile and start the HTTP Server
javac backend/MessManagementServer.java
java backend.MessManagementServer
```
*The server listens on `http://localhost:8080` and provides both the REST API and static file serving.*

### C. Run Python ODBC Audit Script
```bash
# Run standalone audit report
python3 reports/odbc_audit.py

# Filter by student Nishank Chhipa
python3 reports/odbc_audit.py --student 25BCE1642

# Export to CSV
python3 reports/odbc_audit.py --csv reports/ledger_export.csv
```

### D. Access the Web Portal
Open your web browser and navigate to:
```
http://localhost:8080
```
*(Or simply open `index.html` in any modern web browser — the portal features an embedded client-side Oracle simulator with localStorage persistence).*

---

## 5. Demonstration & Viva Walkthrough Guide

### Test Credentials (1-Click Buttons Provided)
- **Chief Mess Warden (Admin):** Username `admin`, Password `admin123`
- **Student Portal (Nishank Chhipa):** Username `25BCE1642`, Password `student123`

### Key Scenarios to Demonstrate
1. **Normal Turnstile Swipe:**
   - Log in as Warden. On the Turnstile POS screen, select student `25BCE1642`.
   - Click **"Swipe BREAKFAST"**. Observe the green confirmation banner, tariff deduction (₹50.00), and balance update.
2. **Duplicate Swipe Guard Demonstration:**
   - Click **"Swipe BREAKFAST"** again for the same student on the same date.
   - Observe the high-contrast red denial banner: `DUPLICATE SWIPE DENIED (-20001): Trigger trg_prevent_duplicate_swipe fired`.
3. **Rebate Absence Conflict Guard:**
   - In the student dropdown, select student `25BCE1244` (Rohan Verma), who has an active medical leave covering today.
   - Click **"Swipe BREAKFAST"**.
   - Observe the high-contrast red denial banner: `REBATE POLICY VIOLATION (-20002): Trigger trg_rebate_swipe_guard fired`.
4. **Billing Engine Cursor Process:**
   - Navigate to **"Billing Engine"**.
   - Select student `25BCE1642`, month `10 (October)`, year `2026`.
   - Click **"Run PL/SQL Billing Calculation"**.
   - Inspect the breakdown: `c_swipes` count, gross amount, `c_rebates` days, rebate credit subsidy, and net payable.
5. **Student Portal:**
   - Log out and log in as student `25BCE1642`.
   - View personalized boarder meta, wallet float, today's meal status tracker, and submit a self-service rebate request.
