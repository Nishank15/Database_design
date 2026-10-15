#!/usr/bin/env python3
"""
===============================================================================
ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM — AUDIT & RECONCILIATION ENGINE
ODBC Reporting & Analytics Module
Course: B.Tech CSE • DBMS Full-Stack Portal
Developer: NISHANK CHHIPA (Reg No: 25BCE1642)
Integration: ODBC / pyodbc with Relational Ledger View & Audit Trail
===============================================================================
"""

import sys
import os
import argparse
import datetime
import json
import csv

def get_connection_string():
    """Constructs ODBC connection string from environment or defaults."""
    dsn = os.environ.get("ORACLE_ODBC_DSN", "OracleMessDSN")
    uid = os.environ.get("ORACLE_ODBC_UID", "c##mess_admin")
    pwd = os.environ.get("ORACLE_ODBC_PWD", "oracle123")
    host = os.environ.get("ORACLE_HOST", "localhost")
    port = os.environ.get("ORACLE_PORT", "1521")
    service = os.environ.get("ORACLE_SERVICE", "ORCLCDB")

    driver = os.environ.get("ORACLE_ODBC_DRIVER", "Oracle in instantclient_19_8")
    
    # Direct DSN-less or DSN-based
    if os.environ.get("USE_DSN"):
        return f"DSN={dsn};UID={uid};PWD={pwd}"
    return f"DRIVER={{{driver}}};DBQ={host}:{port}/{service};UID={uid};PWD={pwd}"


def run_live_odbc_audit(conn_str, student_filter=None):
    """Executes live SQL queries over an active ODBC cursor."""
    try:
        import pyodbc
    except ImportError:
        print("[!] pyodbc is not installed in current Python environment.")
        print("[i] Falling back to intelligent simulated ODBC audit runner.\n")
        return None

    try:
        print(f"[*] Connecting to Oracle Database via ODBC: {conn_str.split('PWD=')[0]}PWD=***")
        conn = pyodbc.connect(conn_str, timeout=5)
        cursor = conn.cursor()

        # Query 1: v_student_mess_ledger
        sql_ledger = """
            SELECT student_id, name, block_name, room_number, mess_type, 
                   wallet_balance, total_swipes_count, total_swipe_expenditure,
                   approved_rebate_count, total_approved_rebate_days
            FROM v_student_mess_ledger
        """
        if student_filter:
            sql_ledger += f" WHERE student_id = '{student_filter}'"
        sql_ledger += " ORDER BY block_name, room_number"

        cursor.execute(sql_ledger)
        columns = [column[0] for column in cursor.description]
        ledger_data = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Query 2: audit_log summary
        cursor.execute("""
            SELECT log_id, action_type, entity_name, entity_id, old_value, new_value, 
                   performed_by, TO_CHAR(logged_at, 'YYYY-MM-DD HH24:MI:SS') as log_time
            FROM audit_log
            ORDER BY log_id DESC
            FETCH FIRST 20 ROWS ONLY
        """)
        audit_cols = [c[0] for c in cursor.description]
        audit_data = [dict(zip(audit_cols, row)) for row in cursor.fetchall()]

        cursor.close()
        conn.close()
        return {"ledger": ledger_data, "audit": audit_data, "mode": "LIVE_ODBC"}

    except Exception as e:
        print(f"[!] ODBC Connection error: {e}")
        print("[i] Launching fallback simulation mode with live-equivalent dataset.\n")
        return None


def get_simulated_audit_dataset(student_filter=None):
    """Generates rich analytical data mirroring the Oracle 3NF suite."""
    ledger = [
        {
            "STUDENT_ID": "25BCE1642",
            "NAME": "NISHANK CHHIPA",
            "BLOCK_NAME": "Block B (Bhabha Hall)",
            "ROOM_NUMBER": "412",
            "MESS_TYPE": "NON_VEG",
            "WALLET_BALANCE": 3450.00,
            "TOTAL_SWIPES_COUNT": 18,
            "TOTAL_SWIPE_EXPENDITURE": 1395.00,
            "APPROVED_REBATE_COUNT": 1,
            "TOTAL_APPROVED_REBATE_DAYS": 4
        },
        {
            "STUDENT_ID": "25BCE1001",
            "NAME": "Aarav Sharma",
            "BLOCK_NAME": "Block A (Aryabhatta Hall)",
            "ROOM_NUMBER": "104",
            "MESS_TYPE": "VEG",
            "WALLET_BALANCE": 1850.00,
            "TOTAL_SWIPES_COUNT": 14,
            "TOTAL_SWIPE_EXPENDITURE": 920.00,
            "APPROVED_REBATE_COUNT": 1,
            "TOTAL_APPROVED_REBATE_DAYS": 4
        },
        {
            "STUDENT_ID": "25BCE1089",
            "NAME": "Diya Iyer",
            "BLOCK_NAME": "Block B (Bhabha Hall)",
            "ROOM_NUMBER": "205",
            "MESS_TYPE": "SPECIAL",
            "WALLET_BALANCE": 4200.00,
            "TOTAL_SWIPES_COUNT": 22,
            "TOTAL_SWIPE_EXPENDITURE": 1780.00,
            "APPROVED_REBATE_COUNT": 0,
            "TOTAL_APPROVED_REBATE_DAYS": 0
        },
        {
            "STUDENT_ID": "25BCE1244",
            "NAME": "Rohan Verma",
            "BLOCK_NAME": "Block C (Charaka Hall)",
            "ROOM_NUMBER": "310",
            "MESS_TYPE": "NON_VEG",
            "WALLET_BALANCE": 520.00,
            "TOTAL_SWIPES_COUNT": 12,
            "TOTAL_SWIPE_EXPENDITURE": 890.00,
            "APPROVED_REBATE_COUNT": 1,
            "TOTAL_APPROVED_REBATE_DAYS": 5
        },
        {
            "STUDENT_ID": "25BCE1560",
            "NAME": "Ananya Patel",
            "BLOCK_NAME": "Block D (Dhanvantari Hall)",
            "ROOM_NUMBER": "118",
            "MESS_TYPE": "VEG",
            "WALLET_BALANCE": 2900.00,
            "TOTAL_SWIPES_COUNT": 16,
            "TOTAL_SWIPE_EXPENDITURE": 1110.00,
            "APPROVED_REBATE_COUNT": 1,
            "TOTAL_APPROVED_REBATE_DAYS": 4
        },
        {
            "STUDENT_ID": "25BCE1780",
            "NAME": "Kabir Reddy",
            "BLOCK_NAME": "Block A (Aryabhatta Hall)",
            "ROOM_NUMBER": "221",
            "MESS_TYPE": "SPECIAL",
            "WALLET_BALANCE": 150.00,
            "TOTAL_SWIPES_COUNT": 8,
            "TOTAL_SWIPE_EXPENDITURE": 610.00,
            "APPROVED_REBATE_COUNT": 0,
            "TOTAL_APPROVED_REBATE_DAYS": 0
        }
    ]

    if student_filter:
        ledger = [row for row in ledger if row["STUDENT_ID"] == student_filter]

    audit = [
        {
            "LOG_ID": 105,
            "ACTION_TYPE": "WALLET_BALANCE_UPDATE",
            "ENTITY_NAME": "STUDENTS",
            "ENTITY_ID": "25BCE1642",
            "OLD_VALUE": "PREV_BALANCE=3545.00",
            "NEW_VALUE": "NEW_BALANCE=3450.00",
            "PERFORMED_BY": "TURNSTILE-GATE-01",
            "LOG_TIME": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        },
        {
            "LOG_ID": 104,
            "ACTION_TYPE": "BILLING_CALCULATED",
            "ENTITY_NAME": "MONTHLY_BILLS",
            "ENTITY_ID": "25BCE1642",
            "OLD_VALUE": None,
            "NEW_VALUE": "Month=10/2026; Gross=1395.00; RebateDays=4; NetPayable=675.00",
            "PERFORMED_BY": "BILLING_ENGINE",
            "LOG_TIME": (datetime.datetime.now() - datetime.timedelta(minutes=15)).strftime("%Y-%m-%d %H:%M:%S")
        },
        {
            "LOG_ID": 103,
            "ACTION_TYPE": "REBATE_APPROVED",
            "ENTITY_NAME": "REBATE_REQUESTS",
            "ENTITY_ID": "12",
            "OLD_VALUE": "PREV_STATUS=PENDING",
            "NEW_VALUE": "NEW_STATUS=APPROVED",
            "PERFORMED_BY": "WARDEN_ADMIN",
            "LOG_TIME": (datetime.datetime.now() - datetime.timedelta(hours=2)).strftime("%Y-%m-%d %H:%M:%S")
        }
    ]

    return {"ledger": ledger, "audit": audit, "mode": "SIMULATED_ODBC_FALLBACK"}


def format_table(headers, rows):
    """Utility to print crisp terminal tables with clean ascii formatting."""
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val)))

    sep = "+-" + "-+-".join("-" * w for w in col_widths) + "-+"
    header_str = "| " + " | ".join(h.ljust(col_widths[i]) for i, h in enumerate(headers)) + " |"

    output = [sep, header_str, sep]
    for row in rows:
        line = "| " + " | ".join(str(val).ljust(col_widths[i]) for i, val in enumerate(row)) + " |"
        output.append(line)
    output.append(sep)
    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(description="Oracle Mess Management ODBC Audit Generator")
    parser.add_argument("--student", help="Filter by Student ID (e.g., 25BCE1642)")
    parser.add_argument("--json", action="store_true", help="Output results in JSON format")
    parser.add_argument("--csv", help="Export ledger results to CSV filepath")
    parser.add_argument("--simulate", action="store_true", help="Force local simulation mode")
    args = parser.parse_args()

    conn_str = get_connection_string()
    
    if args.simulate:
        data = get_simulated_audit_dataset(args.student)
    else:
        data = run_live_odbc_audit(conn_str, args.student)
        if not data:
            data = get_simulated_audit_dataset(args.student)

    if args.json:
        print(json.dumps(data, indent=2, default=str))
        return

    if args.csv:
        with open(args.csv, "w", newline="", encoding="utf-8") as f:
            if data["ledger"]:
                writer = csv.DictWriter(f, fieldnames=data["ledger"][0].keys())
                writer.writeheader()
                writer.writerows(data["ledger"])
        print(f"[✓] Ledger exported successfully to CSV: {args.csv}")
        return

    print("=" * 80)
    print("  ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM — AUDIT & RECONCILIATION")
    print("  Developer: NISHANK CHHIPA (25BCE1642) • B.Tech CSE (Sem 3 DBMS)")
    print(f"  Execution Mode: [{data['mode']}] | Time: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)

    # 1. LEDGER REPORT
    print("\n[SECTION 1: STUDENT MESS RECONCILIATION LEDGER (v_student_mess_ledger)]\n")
    headers = ["ID", "Name", "Block", "Room", "Plan", "Balance", "Swipes", "Spent", "Reb. Days"]
    rows = []
    total_balance = 0.0
    total_spent = 0.0
    total_swipes = 0

    for item in data["ledger"]:
        sid = item.get("STUDENT_ID", "")
        name = item.get("NAME", "")
        block = item.get("BLOCK_NAME", "").split(" ")[0] + " " + item.get("BLOCK_NAME", "").split(" ")[1] if " " in item.get("BLOCK_NAME", "") else item.get("BLOCK_NAME", "")
        room = item.get("ROOM_NUMBER", "")
        mtype = item.get("MESS_TYPE", "")
        bal = float(item.get("WALLET_BALANCE", 0))
        swp = int(item.get("TOTAL_SWIPES_COUNT", 0))
        spnt = float(item.get("TOTAL_SWIPE_EXPENDITURE", 0))
        reb = int(item.get("TOTAL_APPROVED_REBATE_DAYS", 0))

        total_balance += bal
        total_spent += spnt
        total_swipes += swp

        rows.append([sid, name, block, room, mtype, f"₹{bal:,.2f}", swp, f"₹{spnt:,.2f}", reb])

    print(format_table(headers, rows))
    print(f"\n>> Portfolio Aggregates: Total Boarders: {len(data['ledger'])} | Total Swipes: {total_swipes} | Gross Tariff: ₹{total_spent:,.2f} | Float: ₹{total_balance:,.2f}")

    # 2. AUDIT JOURNAL
    print("\n[SECTION 2: IMMUTABLE AUDIT TRAIL (audit_log — Latest Actions)]\n")
    audit_headers = ["Log ID", "Action", "Target", "Entity ID", "Performed By", "Timestamp"]
    audit_rows = []
    for a in data["audit"][:10]:
        lid = a.get("LOG_ID", "")
        act = a.get("ACTION_TYPE", "")
        ent = a.get("ENTITY_NAME", "")
        eid = a.get("ENTITY_ID", "")
        usr = a.get("PERFORMED_BY", "")
        ts = str(a.get("LOG_TIME", ""))[:19]
        audit_rows.append([lid, act, ent, eid, usr, ts])

    print(format_table(audit_headers, audit_rows))
    print("\n[✓] Audit query execution concluded cleanly.\n")


if __name__ == "__main__":
    main()
