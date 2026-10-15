package backend;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.*;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ============================================================================
 * ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM — FULL-STACK BACKEND SERVER
 * Course: B.Tech CSE • DBMS Project
 * Developer: NISHANK CHHIPA (Reg No: 25BCE1642)
 * Stack: Oracle JDBC (CallableStatement / PreparedStatement) + In-Memory Simulation
 * ============================================================================
 */
public class MessManagementServer {

    private static final int PORT = 8080;
    private static Connection oracleConn = null;
    private static boolean isOracleLive = false;

    // Developer Credits
    public static final String DEVELOPER_NAME = "NISHANK CHHIPA";
    public static final String REG_NO = "25BCE1642";
    public static final String COURSE_STACK = "B.Tech CSE • DBMS Project (Oracle PL/SQL • JDBC • ODBC)";

    // In-Memory Simulation State (Zero-Dependency Oracle Engine)
    public static class Boarder {
        public String studentId;
        public String name;
        public String email;
        public String phone;
        public String blockId;
        public String roomNumber;
        public String messType;
        public double walletBalance;
        public String status;

        public Boarder(String id, String n, String em, String ph, String blk, String rm, String mt, double bal) {
            this.studentId = id; this.name = n; this.email = em; this.phone = ph;
            this.blockId = blk; this.roomNumber = rm; this.messType = mt;
            this.walletBalance = bal; this.status = "ACTIVE";
        }
    }

    public static class MealCategory {
        public String categoryId;
        public String categoryName;
        public String startTime;
        public String endTime;
        public double defaultRate;

        public MealCategory(String id, String name, String st, String et, double rate) {
            this.categoryId = id; this.categoryName = name; this.startTime = st; this.endTime = et; this.defaultRate = rate;
        }
    }

    public static class SwipeRecord {
        public int swipeId;
        public String studentId;
        public String categoryId;
        public String swipeDate; // YYYY-MM-DD
        public String swipeTime; // HH:mm:ss
        public double rateCharged;
        public String turnstileId;
        public String status;

        public SwipeRecord(int id, String sid, String cid, String dt, String tm, double rate, String tid, String stat) {
            this.swipeId = id; this.studentId = sid; this.categoryId = cid;
            this.swipeDate = dt; this.swipeTime = tm; this.rateCharged = rate;
            this.turnstileId = tid; this.status = stat;
        }
    }

    public static class RebateRecord {
        public int rebateId;
        public String studentId;
        public String fromDate; // YYYY-MM-DD
        public String toDate;   // YYYY-MM-DD
        public String reason;
        public String status;   // PENDING, APPROVED, REJECTED, REVOKED
        public String appliedAt;
        public String remarks;

        public RebateRecord(int id, String sid, String from, String to, String rsn, String stat, String remarks) {
            this.rebateId = id; this.studentId = sid; this.fromDate = from; this.toDate = to;
            this.reason = rsn; this.status = stat; this.remarks = remarks;
            this.appliedAt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date());
        }
    }

    public static class BillRecord {
        public int billId;
        public String studentId;
        public int month;
        public int year;
        public int totalSwipes;
        public double grossAmount;
        public int rebateDays;
        public double rebateCredit;
        public double netPayable;
        public String paymentStatus;
        public String generatedAt;

        public BillRecord(int id, String sid, int m, int y, int swp, double gross, int rdays, double rcredit, double net, String stat) {
            this.billId = id; this.studentId = sid; this.month = m; this.year = y;
            this.totalSwipes = swp; this.grossAmount = gross; this.rebateDays = rdays;
            this.rebateCredit = rcredit; this.netPayable = net; this.paymentStatus = stat;
            this.generatedAt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date());
        }
    }

    public static class AuditItem {
        public int logId;
        public String actionType;
        public String entityName;
        public String entityId;
        public String oldValue;
        public String newValue;
        public String performedBy;
        public String timestamp;

        public AuditItem(int id, String act, String ent, String eid, String oldV, String newV, String by) {
            this.logId = id; this.actionType = act; this.entityName = ent; this.entityId = eid;
            this.oldValue = oldV; this.newValue = newV; this.performedBy = by;
            this.timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date());
        }
    }

    // Storage maps
    public static final Map<String, Boarder> boarders = new ConcurrentHashMap<>();
    public static final Map<String, MealCategory> categories = new LinkedHashMap<>();
    public static final List<SwipeRecord> swipes = new CopyOnWriteArrayList<>();
    public static final List<RebateRecord> rebates = new CopyOnWriteArrayList<>();
    public static final List<BillRecord> bills = new CopyOnWriteArrayList<>();
    public static final List<AuditItem> auditLogs = new CopyOnWriteArrayList<>();
    public static final AtomicInteger swipeIdSeq = new AtomicInteger(100);
    public static final AtomicInteger rebateIdSeq = new AtomicInteger(20);
    public static final AtomicInteger billIdSeq = new AtomicInteger(10);
    public static final AtomicInteger auditIdSeq = new AtomicInteger(500);

    public static void main(String[] args) throws IOException {
        initSimulationSeed();
        initOracleJdbcConnection();

        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);

        // Core API Endpoints
        server.createContext("/api/system/info", new InfoHandler());
        server.createContext("/api/auth/login", new AuthHandler());
        server.createContext("/api/students", new StudentsHandler());
        server.createContext("/api/students/add-funds", new AddFundsHandler());
        server.createContext("/api/students/update", new StudentUpdateHandler());
        server.createContext("/api/students/delete", new StudentDeleteHandler());
        server.createContext("/api/turnstile/swipe", new TurnstileSwipeHandler());
        server.createContext("/api/turnstile/status", new TurnstileStatusHandler());
        server.createContext("/api/turnstile/reset", new ResetSwipesHandler());
        server.createContext("/api/rebates", new RebatesHandler());
        server.createContext("/api/rebates/action", new RebateActionHandler());
        server.createContext("/api/billing/calculate", new BillingCalculateHandler());
        server.createContext("/api/billing/history", new BillingHistoryHandler());
        server.createContext("/api/ledger", new LedgerHandler());
        server.createContext("/api/audit", new AuditHandler());

        // Static File Server
        server.createContext("/", new StaticFileHandler());

        server.setExecutor(java.util.concurrent.Executors.newCachedThreadPool());
        server.start();

        System.out.println("===============================================================================");
        System.out.println("  ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM (PORTAL BACKEND)");
        System.out.println("  Author: " + DEVELOPER_NAME + " | Reg No: " + REG_NO);
        System.out.println("  Stack: " + COURSE_STACK);
        System.out.println("  Server listening at: http://localhost:" + PORT);
        System.out.println("  Oracle DB Live Status: " + (isOracleLive ? "CONNECTED (ojdbc11)" : "IN-MEMORY ORACLE SIMULATOR"));
        System.out.println("===============================================================================");
    }

    private static void initSimulationSeed() {
        // Categories
        categories.put("CAT-BF", new MealCategory("CAT-BF", "BREAKFAST", "07:30", "09:30", 50.00));
        categories.put("CAT-LN", new MealCategory("CAT-LN", "LUNCH", "12:30", "14:30", 90.00));
        categories.put("CAT-SN", new MealCategory("CAT-SN", "SNACKS", "17:00", "18:30", 35.00));
        categories.put("CAT-DN", new MealCategory("CAT-DN", "DINNER", "19:30", "21:30", 95.00));

        // Boarders
        boarders.put("25BCE1642", new Boarder("25BCE1642", "NISHANK CHHIPA", "nishank.chhipa2025@vitstudent.ac.in", "+91 94140 88219", "BLK-B", "412", "NON_VEG", 3450.00));
        boarders.put("25BCE1001", new Boarder("25BCE1001", "Aarav Sharma", "aarav.sharma2025@vitstudent.ac.in", "+91 98765 43210", "BLK-A", "104", "VEG", 1850.00));
        boarders.put("25BCE1089", new Boarder("25BCE1089", "Diya Iyer", "diya.iyer2025@vitstudent.ac.in", "+91 98112 34567", "BLK-B", "205", "SPECIAL", 4200.00));
        boarders.put("25BCE1244", new Boarder("25BCE1244", "Rohan Verma", "rohan.verma2025@vitstudent.ac.in", "+91 97234 56789", "BLK-C", "310", "NON_VEG", 520.00));
        boarders.put("25BCE1560", new Boarder("25BCE1560", "Ananya Patel", "ananya.patel2025@vitstudent.ac.in", "+91 96543 21098", "BLK-D", "118", "VEG", 2900.00));
        boarders.put("25BCE1780", new Boarder("25BCE1780", "Kabir Reddy", "kabir.reddy2025@vitstudent.ac.in", "+91 95432 10987", "BLK-A", "221", "SPECIAL", 150.00));

        // Rebates
        LocalDate today = LocalDate.now();
        rebates.add(new RebateRecord(1, "25BCE1001", today.minusDays(10).toString(), today.minusDays(7).toString(), "Inter-University Hackathon in Bengaluru", "APPROVED", "OD Certificate verified"));
        rebates.add(new RebateRecord(2, "25BCE1244", today.minusDays(2).toString(), today.plusDays(2).toString(), "Medical leave with home warden intimation", "APPROVED", "Doctor slip on file"));
        rebates.add(new RebateRecord(3, "25BCE1642", today.plusDays(3).toString(), today.plusDays(6).toString(), "Family function in Jaipur, Rajasthan", "PENDING", "Pending parent verification"));
        rebates.add(new RebateRecord(4, "25BCE1560", today.minusDays(15).toString(), today.minusDays(12).toString(), "Symposium research paper presentation", "APPROVED", "Academic OD approved"));

        // Historical Swipes for student 25BCE1642
        swipes.add(new SwipeRecord(swipeIdSeq.incrementAndGet(), "25BCE1642", "CAT-BF", today.minusDays(1).toString(), "08:15:20", 50.00, "TURNSTILE-GATE-01", "ACCEPTED"));
        swipes.add(new SwipeRecord(swipeIdSeq.incrementAndGet(), "25BCE1642", "CAT-LN", today.minusDays(1).toString(), "13:05:44", 90.00, "TURNSTILE-GATE-01", "ACCEPTED"));
        swipes.add(new SwipeRecord(swipeIdSeq.incrementAndGet(), "25BCE1642", "CAT-DN", today.minusDays(1).toString(), "20:10:12", 95.00, "TURNSTILE-GATE-02", "ACCEPTED"));

        auditLogs.add(new AuditItem(auditIdSeq.incrementAndGet(), "SYSTEM_INIT", "CORE", "0", null, "Mess Database Simulator initialized with 3NF seed", "SYSTEM"));
    }

    private static void initOracleJdbcConnection() {
        String url = System.getenv("ORACLE_JDBC_URL");
        String user = System.getenv("ORACLE_USER");
        String pass = System.getenv("ORACLE_PASSWORD");

        if (url == null || url.trim().isEmpty()) {
            url = "jdbc:oracle:thin:@localhost:1521/ORCLCDB";
            user = "c##mess_admin";
            pass = "oracle123";
        }

        try {
            Class.forName("oracle.jdbc.OracleDriver");
            DriverManager.setLoginTimeout(3);
            oracleConn = DriverManager.getConnection(url, user, pass);
            isOracleLive = true;
            System.out.println("[✓] Successfully connected to live Oracle Database via JDBC!");
        } catch (Throwable t) {
            isOracleLive = false;
            System.out.println("[i] Oracle Database not detected locally (" + t.getMessage() + ").");
            System.out.println("[✓] Running in Zero-Dependency High-Fidelity Oracle Simulation Engine.");
        }
    }

    // ------------------------------------------------------------------------
    // HTTP HANDLERS
    // ------------------------------------------------------------------------

    static class InfoHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            String json = "{"
                    + "\"developer\":\"" + DEVELOPER_NAME + "\","
                    + "\"regNo\":\"" + REG_NO + "\","
                    + "\"courseStack\":\"" + COURSE_STACK + "\","
                    + "\"oracleLive\":" + isOracleLive + ","
                    + "\"serverTime\":\"" + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date()) + "\""
                    + "}";
            sendJsonResponse(ex, 200, json);
        }
    }

    static class AuthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if (!"POST".equalsIgnoreCase(ex.getRequestMethod())) {
                sendJsonResponse(ex, 405, "{\"error\":\"Method not allowed\"}");
                return;
            }

            String body = readBody(ex);
            Map<String, String> params = parseJsonSimple(body);
            String u = params.get("username");
            String p = params.get("password");

            if ("admin".equalsIgnoreCase(u) && "admin123".equals(p)) {
                sendJsonResponse(ex, 200, "{\"success\":true,\"role\":\"ADMIN\",\"displayName\":\"Chief Mess Warden\",\"username\":\"admin\"}");
                return;
            } else if ("warden_b".equalsIgnoreCase(u) && "warden123".equals(p)) {
                sendJsonResponse(ex, 200, "{\"success\":true,\"role\":\"ADMIN\",\"displayName\":\"Bhabha Hall Warden\",\"username\":\"warden_b\"}");
                return;
            } else if (boarders.containsKey(u) && "student123".equals(p)) {
                Boarder b = boarders.get(u);
                sendJsonResponse(ex, 200, "{\"success\":true,\"role\":\"STUDENT\",\"displayName\":\"" + b.name + "\",\"username\":\"" + b.studentId + "\",\"studentId\":\"" + b.studentId + "\"}");
                return;
            }

            sendJsonResponse(ex, 401, "{\"success\":false,\"error\":\"Invalid credentials. Use admin/admin123 or 25BCE1642/student123\"}");
        }
    }

    static class StudentsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if ("GET".equalsIgnoreCase(ex.getRequestMethod())) {
                StringBuilder sb = new StringBuilder("[");
                int idx = 0;
                for (Boarder b : boarders.values()) {
                    if (idx++ > 0) sb.append(",");
                    sb.append("{")
                      .append("\"studentId\":\"").append(b.studentId).append("\",")
                      .append("\"name\":\"").append(escape(b.name)).append("\",")
                      .append("\"email\":\"").append(escape(b.email)).append("\",")
                      .append("\"phone\":\"").append(escape(b.phone)).append("\",")
                      .append("\"blockId\":\"").append(escape(b.blockId)).append("\",")
                      .append("\"roomNumber\":\"").append(escape(b.roomNumber)).append("\",")
                      .append("\"messType\":\"").append(b.messType).append("\",")
                      .append("\"walletBalance\":").append(b.walletBalance).append(",")
                      .append("\"status\":\"").append(b.status).append("\"")
                      .append("}");
                }
                sb.append("]");
                sendJsonResponse(ex, 200, sb.toString());
            } else if ("POST".equalsIgnoreCase(ex.getRequestMethod())) {
                // Register student
                Map<String, String> p = parseJsonSimple(readBody(ex));
                String sid = p.get("studentId");
                String name = p.get("name");
                String email = p.get("email");
                String phone = p.get("phone");
                String blk = p.get("blockId");
                String rm = p.get("roomNumber");
                String mtype = p.getOrDefault("messType", "VEG");
                double bal = 0;
                try { bal = Double.parseDouble(p.getOrDefault("initialBalance", "0")); } catch (Exception ignored) {}

                if (sid == null || name == null || sid.trim().isEmpty()) {
                    sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Student ID and Name are required.\"}");
                    return;
                }

                if (boarders.containsKey(sid)) {
                    sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Student ID " + sid + " already exists.\"}");
                    return;
                }

                Boarder nb = new Boarder(sid, name, email, phone, blk, rm, mtype, bal);
                boarders.put(sid, nb);
                auditLogs.add(new AuditItem(auditIdSeq.incrementAndGet(), "STUDENT_ENROLLED", "STUDENTS", sid, null, "Name=" + name + "; Block=" + blk, "WARDEN_PORTAL"));

                sendJsonResponse(ex, 200, "{\"success\":true,\"message\":\"Boarder " + name + " (" + sid + ") enrolled successfully.\"}");
            }
        }
    }

    static class AddFundsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if (!"POST".equalsIgnoreCase(ex.getRequestMethod())) {
                sendJsonResponse(ex, 405, "{\"error\":\"POST required\"}");
                return;
            }

            Map<String, String> p = parseJsonSimple(readBody(ex));
            String sid = p.get("studentId");
            String src = p.getOrDefault("source", "ADMIN");
            double amount = 0;
            try {
                amount = Double.parseDouble(p.getOrDefault("amount", "0"));
            } catch (Exception ignored) {}

            if (sid == null || sid.trim().isEmpty() || amount <= 0) {
                sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Valid Student ID and positive amount are required.\"}");
                return;
            }

            if (isOracleLive && oracleConn != null) {
                try {
                    CallableStatement cs = oracleConn.prepareCall("{call mess_ops_pkg.top_up_wallet(?, ?, ?, ?, ?, ?)}");
                    cs.setString(1, sid);
                    cs.setDouble(2, amount);
                    cs.setString(3, src);
                    cs.registerOutParameter(4, Types.VARCHAR);
                    cs.registerOutParameter(5, Types.DOUBLE);
                    cs.registerOutParameter(6, Types.VARCHAR);
                    cs.execute();
                    String status = cs.getString(4);
                    double newBal = cs.getDouble(5);
                    String msg = cs.getString(6);
                    cs.close();
                    boolean ok = "SUCCESS".equalsIgnoreCase(status);
                    Boarder b = boarders.get(sid);
                    if (b != null) b.walletBalance = newBal;
                    sendJsonResponse(ex, ok ? 200 : 400, "{\"success\":" + ok + ",\"studentId\":\"" + sid + "\",\"amount\":" + amount + ",\"newBalance\":" + newBal + ",\"message\":\"" + escape(msg) + "\"}");
                    return;
                } catch (Exception e) {
                    System.err.println("Live Oracle top_up_wallet call failed: " + e.getMessage());
                }
            }

            Boarder b = boarders.get(sid);
            if (b == null) {
                sendJsonResponse(ex, 404, "{\"success\":false,\"message\":\"Student ID [" + sid + "] not found in registry.\"}");
                return;
            }

            double oldBal = b.walletBalance;
            b.walletBalance += amount;
            auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "WALLET_TOP_UP", "STUDENTS", sid, "PREV=₹" + String.format("%.2f", oldBal), "CREDIT=₹" + String.format("%.2f", amount) + "; NEW=₹" + String.format("%.2f", b.walletBalance) + "; SOURCE=" + src, src));

            String msg = "Successfully credited ₹" + String.format("%.2f", amount) + " to " + b.name + " (" + sid + "). New Balance: ₹" + String.format("%.2f", b.walletBalance);
            sendJsonResponse(ex, 200, "{\"success\":true,\"studentId\":\"" + sid + "\",\"amount\":" + amount + ",\"newBalance\":" + b.walletBalance + ",\"message\":\"" + escape(msg) + "\"}");
        }
    }

    static class StudentUpdateHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if (!"POST".equalsIgnoreCase(ex.getRequestMethod())) {
                sendJsonResponse(ex, 405, "{\"error\":\"POST required\"}");
                return;
            }

            Map<String, String> p = parseJsonSimple(readBody(ex));
            String sid = p.get("studentId");
            String name = p.get("name");
            String block = p.get("blockId");
            String room = p.get("roomNumber");
            String mess = p.getOrDefault("messType", "VEG");
            String stat = p.getOrDefault("status", "ACTIVE");

            if (sid == null || sid.trim().isEmpty() || name == null || name.trim().isEmpty()) {
                sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Student ID and Name are required.\"}");
                return;
            }

            if (isOracleLive && oracleConn != null) {
                try {
                    CallableStatement cs = oracleConn.prepareCall("{call mess_ops_pkg.update_student(?, ?, ?, ?, ?, ?, ?, ?)}");
                    cs.setString(1, sid);
                    cs.setString(2, name);
                    cs.setString(3, block);
                    cs.setString(4, room);
                    cs.setString(5, mess);
                    cs.setString(6, stat);
                    cs.registerOutParameter(7, Types.VARCHAR);
                    cs.registerOutParameter(8, Types.VARCHAR);
                    cs.execute();
                    String status = cs.getString(7);
                    String msg = cs.getString(8);
                    cs.close();
                    boolean ok = "SUCCESS".equalsIgnoreCase(status);
                    Boarder b = boarders.get(sid);
                    if (b != null) {
                        b.name = name; b.blockId = block; b.roomNumber = room; b.messType = mess; b.status = stat;
                    }
                    sendJsonResponse(ex, ok ? 200 : 400, "{\"success\":" + ok + ",\"message\":\"" + escape(msg) + "\"}");
                    return;
                } catch (Exception e) {
                    System.err.println("Live Oracle update_student call failed: " + e.getMessage());
                }
            }

            Boarder b = boarders.get(sid);
            if (b == null) {
                sendJsonResponse(ex, 404, "{\"success\":false,\"message\":\"Student ID [" + sid + "] not found in registry.\"}");
                return;
            }

            b.name = name;
            if (block != null && !block.isEmpty()) b.blockId = block;
            if (room != null && !room.isEmpty()) b.roomNumber = room;
            if (mess != null && !mess.isEmpty()) b.messType = mess;
            if (stat != null && !stat.isEmpty()) b.status = stat;

            auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "STUDENT_UPDATED", "STUDENTS", sid, null, "Name=" + name + "; Block=" + block + "; Room=" + room + "; Mess=" + mess + "; Status=" + stat, "WARDEN_ADMIN"));

            sendJsonResponse(ex, 200, "{\"success\":true,\"message\":\"Boarder [" + name + " (" + sid + ")] profile updated successfully.\"}");
        }
    }

    static class StudentDeleteHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if (!"POST".equalsIgnoreCase(ex.getRequestMethod())) {
                sendJsonResponse(ex, 405, "{\"error\":\"POST required\"}");
                return;
            }

            Map<String, String> p = parseJsonSimple(readBody(ex));
            String sid = p.get("studentId");

            if (sid == null || sid.trim().isEmpty()) {
                sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Student ID is required.\"}");
                return;
            }

            if (isOracleLive && oracleConn != null) {
                try {
                    CallableStatement cs = oracleConn.prepareCall("{call mess_ops_pkg.deregister_student(?, ?, ?)}");
                    cs.setString(1, sid);
                    cs.registerOutParameter(2, Types.VARCHAR);
                    cs.registerOutParameter(3, Types.VARCHAR);
                    cs.execute();
                    String status = cs.getString(2);
                    String msg = cs.getString(3);
                    cs.close();
                    boolean ok = "SUCCESS".equalsIgnoreCase(status);
                    boarders.remove(sid);
                    swipes.removeIf(s -> s.studentId.equalsIgnoreCase(sid));
                    rebates.removeIf(r -> r.studentId.equalsIgnoreCase(sid));
                    bills.removeIf(b -> b.studentId.equalsIgnoreCase(sid));
                    sendJsonResponse(ex, ok ? 200 : 400, "{\"success\":" + ok + ",\"message\":\"" + escape(msg) + "\"}");
                    return;
                } catch (Exception e) {
                    System.err.println("Live Oracle deregister_student call failed: " + e.getMessage());
                }
            }

            Boarder b = boarders.remove(sid);
            if (b == null) {
                sendJsonResponse(ex, 404, "{\"success\":false,\"message\":\"Student ID [" + sid + "] not found in registry.\"}");
                return;
            }

            swipes.removeIf(s -> s.studentId.equalsIgnoreCase(sid));
            rebates.removeIf(r -> r.studentId.equalsIgnoreCase(sid));
            bills.removeIf(bll -> bll.studentId.equalsIgnoreCase(sid));

            auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "STUDENT_DEREGISTERED", "STUDENTS", sid, null, "Deleted student [" + b.name + " (" + sid + ")] and cleaned up associated records", "WARDEN_ADMIN"));

            sendJsonResponse(ex, 200, "{\"success\":true,\"message\":\"Boarder [" + b.name + " (" + sid + ")] has been deregistered and deleted successfully.\"}");
        }
    }

    static class TurnstileStatusHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            String query = ex.getRequestURI().getQuery();
            Map<String, String> qp = parseQuery(query);
            String sid = qp.get("studentId");
            String dt = qp.getOrDefault("date", LocalDate.now().toString());

            Boarder b = boarders.get(sid);
            if (b == null) {
                sendJsonResponse(ex, 404, "{\"error\":\"Student not found\"}");
                return;
            }

            // Check if student has active approved rebate covering date
            boolean hasRebate = false;
            String rebateReason = "";
            for (RebateRecord r : rebates) {
                if (r.studentId.equalsIgnoreCase(sid) && "APPROVED".equalsIgnoreCase(r.status)) {
                    if (dt.compareTo(r.fromDate) >= 0 && dt.compareTo(r.toDate) <= 0) {
                        hasRebate = true;
                        rebateReason = r.reason + " (" + r.fromDate + " to " + r.toDate + ")";
                        break;
                    }
                }
            }

            // Check swiped slots for this date
            Map<String, Boolean> swipedSlots = new HashMap<>();
            for (String catId : categories.keySet()) {
                swipedSlots.put(catId, false);
            }

            for (SwipeRecord sr : swipes) {
                if (sr.studentId.equalsIgnoreCase(sid) && sr.swipeDate.equals(dt) && "ACCEPTED".equalsIgnoreCase(sr.status)) {
                    swipedSlots.put(sr.categoryId, true);
                }
            }

            StringBuilder sb = new StringBuilder("{");
            sb.append("\"studentId\":\"").append(b.studentId).append("\",")
              .append("\"name\":\"").append(escape(b.name)).append("\",")
              .append("\"blockId\":\"").append(b.blockId).append("\",")
              .append("\"roomNumber\":\"").append(b.roomNumber).append("\",")
              .append("\"messType\":\"").append(b.messType).append("\",")
              .append("\"walletBalance\":").append(b.walletBalance).append(",")
              .append("\"queryDate\":\"").append(dt).append("\",")
              .append("\"onRebate\":").append(hasRebate).append(",")
              .append("\"rebateDetails\":\"").append(escape(rebateReason)).append("\",")
              .append("\"slots\":{");

            int idx = 0;
            for (MealCategory c : categories.values()) {
                if (idx++ > 0) sb.append(",");
                boolean swiped = swipedSlots.getOrDefault(c.categoryId, false);
                sb.append("\"").append(c.categoryId).append("\":{")
                  .append("\"name\":\"").append(c.categoryName).append("\",")
                  .append("\"rate\":").append(c.defaultRate).append(",")
                  .append("\"swiped\":").append(swiped).append(",")
                  .append("\"status\":\"").append(swiped ? "SWIPED" : "AVAILABLE").append("\"")
                  .append("}");
            }
            sb.append("}}");
            sendJsonResponse(ex, 200, sb.toString());
        }
    }

    static class TurnstileSwipeHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if (!"POST".equalsIgnoreCase(ex.getRequestMethod())) {
                sendJsonResponse(ex, 405, "{\"error\":\"POST required\"}");
                return;
            }

            Map<String, String> p = parseJsonSimple(readBody(ex));
            String sid = p.get("studentId");
            String catId = p.get("categoryId");
            String swipeDate = p.getOrDefault("swipeDate", LocalDate.now().toString());
            String turnstileId = p.getOrDefault("turnstileId", "TURNSTILE-GATE-01");

            // Execute via Oracle JDBC Stored Procedure if connected!
            if (isOracleLive && oracleConn != null) {
                try {
                    CallableStatement cs = oracleConn.prepareCall("{call mess_ops_pkg.record_turnstile_swipe(?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?)}");
                    cs.setString(1, sid);
                    cs.setString(2, catId);
                    cs.setString(3, swipeDate);
                    cs.setString(4, turnstileId);
                    cs.registerOutParameter(5, Types.VARCHAR);
                    cs.registerOutParameter(6, Types.VARCHAR);
                    cs.execute();
                    String status = cs.getString(5);
                    String message = cs.getString(6);
                    cs.close();

                    boolean success = "SUCCESS".equalsIgnoreCase(status);
                    sendJsonResponse(ex, 200, "{\"success\":" + success + ",\"status\":\"" + status + "\",\"message\":\"" + escape(message) + "\",\"source\":\"ORACLE_PLSQL_JDBC\"}");
                    return;
                } catch (Exception e) {
                    System.err.println("Live Oracle JDBC call failed, falling back to local trigger simulator: " + e.getMessage());
                }
            }

            // Execute via In-Memory PL/SQL Trigger Simulation
            Boarder b = boarders.get(sid);
            if (b == null) {
                sendJsonResponse(ex, 200, "{\"success\":false,\"status\":\"DENIED\",\"message\":\"ACCESS DENIED: Student ID [" + sid + "] not found.\"}");
                return;
            }

            MealCategory cat = categories.get(catId);
            if (cat == null) {
                sendJsonResponse(ex, 200, "{\"success\":false,\"status\":\"DENIED\",\"message\":\"INVALID SLOT: Category [" + catId + "] not recognized.\"}");
                return;
            }

            // Constraint 1: TRIGGER trg_prevent_duplicate_swipe
            for (SwipeRecord sr : swipes) {
                if (sr.studentId.equalsIgnoreCase(sid) && sr.categoryId.equalsIgnoreCase(catId) && sr.swipeDate.equals(swipeDate) && "ACCEPTED".equalsIgnoreCase(sr.status)) {
                    sendJsonResponse(ex, 200, "{\"success\":false,\"status\":\"DENIED\",\"trigger\":\"trg_prevent_duplicate_swipe\",\"message\":\"DUPLICATE SWIPE VIOLATION: Student [" + sid + "] has already swiped for " + cat.categoryName + " on " + swipeDate + ".\"}");
                    return;
                }
            }

            // Constraint 2: TRIGGER trg_rebate_swipe_guard
            for (RebateRecord r : rebates) {
                if (r.studentId.equalsIgnoreCase(sid) && "APPROVED".equalsIgnoreCase(r.status)) {
                    if (swipeDate.compareTo(r.fromDate) >= 0 && swipeDate.compareTo(r.toDate) <= 0) {
                        sendJsonResponse(ex, 200, "{\"success\":false,\"status\":\"DENIED\",\"trigger\":\"trg_rebate_swipe_guard\",\"message\":\"REBATE LEAVE CONFLICT: Student [" + sid + "] is on APPROVED mess rebate leave (" + r.fromDate + " to " + r.toDate + "). Swipes blocked.\"}");
                        return;
                    }
                }
            }

            // Constraint 3: Minimum wallet balance check
            if (b.walletBalance < cat.defaultRate) {
                sendJsonResponse(ex, 200, "{\"success\":false,\"status\":\"DENIED\",\"message\":\"INSUFFICIENT BALANCE: Wallet has ₹" + String.format("%.2f", b.walletBalance) + ", required tariff is ₹" + String.format("%.2f", cat.defaultRate) + ".\"}");
                return;
            }

            // Execution: Record swipe & deduct tariff
            int newSwipeId = swipeIdSeq.incrementAndGet();
            String swipeTime = new SimpleDateFormat("HH:mm:ss").format(new java.util.Date());
            SwipeRecord record = new SwipeRecord(newSwipeId, sid, catId, swipeDate, swipeTime, cat.defaultRate, turnstileId, "ACCEPTED");
            swipes.add(0, record);

            double oldBal = b.walletBalance;
            b.walletBalance -= cat.defaultRate;

            auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "WALLET_BALANCE_UPDATE", "STUDENTS", sid, "PREV=" + String.format("%.2f", oldBal), "NEW=" + String.format("%.2f", b.walletBalance), turnstileId));

            String msg = "ACCESS GRANTED: " + cat.categoryName + " recorded at " + turnstileId + ". Tariff ₹" + String.format("%.2f", cat.defaultRate) + " deducted. Remaining Balance: ₹" + String.format("%.2f", b.walletBalance);
            sendJsonResponse(ex, 200, "{\"success\":true,\"status\":\"SUCCESS\",\"message\":\"" + escape(msg) + "\",\"newBalance\":" + b.walletBalance + ",\"swipeId\":" + newSwipeId + "}");
        }
    }

    static class ResetSwipesHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            String today = LocalDate.now().toString();
            swipes.removeIf(sr -> sr.swipeDate.equals(today));
            auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "DEMO_RESET", "MEAL_SWIPES", "ALL", null, "Cleared today's swipe records for test walkthrough", "ADMIN_PANEL"));

            sendJsonResponse(ex, 200, "{\"success\":true,\"message\":\"Today's turnstile swipe records successfully reset for live demo walkthrough.\"}");
        }
    }

    static class RebatesHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            if ("GET".equalsIgnoreCase(ex.getRequestMethod())) {
                StringBuilder sb = new StringBuilder("[");
                int idx = 0;
                for (RebateRecord r : rebates) {
                    if (idx++ > 0) sb.append(",");
                    Boarder b = boarders.get(r.studentId);
                    String sname = (b != null) ? b.name : r.studentId;
                    sb.append("{")
                      .append("\"rebateId\":").append(r.rebateId).append(",")
                      .append("\"studentId\":\"").append(r.studentId).append("\",")
                      .append("\"studentName\":\"").append(escape(sname)).append("\",")
                      .append("\"fromDate\":\"").append(r.fromDate).append("\",")
                      .append("\"toDate\":\"").append(r.toDate).append("\",")
                      .append("\"reason\":\"").append(escape(r.reason)).append("\",")
                      .append("\"status\":\"").append(r.status).append("\",")
                      .append("\"remarks\":\"").append(escape(r.remarks != null ? r.remarks : "")).append("\",")
                      .append("\"appliedAt\":\"").append(r.appliedAt).append("\"")
                      .append("}");
                }
                sb.append("]");
                sendJsonResponse(ex, 200, sb.toString());
            } else if ("POST".equalsIgnoreCase(ex.getRequestMethod())) {
                Map<String, String> p = parseJsonSimple(readBody(ex));
                String sid = p.get("studentId");
                String from = p.get("fromDate");
                String to = p.get("toDate");
                String reason = p.getOrDefault("reason", "Personal Leave");

                if (from == null || to == null || from.compareTo(to) > 0) {
                    sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Invalid dates: To Date must be on or after From Date.\"}");
                    return;
                }

                int rid = rebateIdSeq.incrementAndGet();
                RebateRecord nr = new RebateRecord(rid, sid, from, to, reason, "PENDING", "Awaiting Warden Approval");
                rebates.add(0, nr);
                auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "REBATE_APPLIED", "REBATE_REQUESTS", String.valueOf(rid), null, "Dates=" + from + " to " + to, sid));

                sendJsonResponse(ex, 200, "{\"success\":true,\"message\":\"Rebate application #" + rid + " submitted successfully.\",\"rebateId\":" + rid + "}");
            }
        }
    }

    static class RebateActionHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            Map<String, String> p = parseJsonSimple(readBody(ex));
            int rid = Integer.parseInt(p.getOrDefault("rebateId", "0"));
            String action = p.getOrDefault("action", "").toUpperCase();
            String adminUser = p.getOrDefault("adminUser", "warden_admin");

            for (RebateRecord r : rebates) {
                if (r.rebateId == rid) {
                    String oldStatus = r.status;
                    if ("APPROVE".equals(action)) {
                        r.status = "APPROVED";
                        r.remarks = "Approved by Warden " + adminUser;
                    } else if ("REJECT".equals(action)) {
                        r.status = "REJECTED";
                        r.remarks = "Rejected by Warden " + adminUser;
                    } else if ("REVOKE".equals(action)) {
                        r.status = "REVOKED";
                        r.remarks = "Revoked upon student/warden request";
                    } else {
                        sendJsonResponse(ex, 400, "{\"success\":false,\"message\":\"Invalid action.\"}");
                        return;
                    }

                    auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "REBATE_" + action, "REBATE_REQUESTS", String.valueOf(rid), oldStatus, r.status, adminUser));
                    sendJsonResponse(ex, 200, "{\"success\":true,\"message\":\"Rebate #" + rid + " status updated to " + r.status + ".\"}");
                    return;
                }
            }

            sendJsonResponse(ex, 404, "{\"success\":false,\"message\":\"Rebate #" + rid + " not found.\"}");
        }
    }

    static class BillingCalculateHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            Map<String, String> p = parseJsonSimple(readBody(ex));
            String sid = p.get("studentId");
            int m = Integer.parseInt(p.getOrDefault("month", String.valueOf(LocalDate.now().getMonthValue())));
            int y = Integer.parseInt(p.getOrDefault("year", String.valueOf(LocalDate.now().getYear())));

            // PL/SQL Cursor Logic Simulation
            int totalSwipes = 0;
            double gross = 0.0;
            for (SwipeRecord sr : swipes) {
                if (sr.studentId.equalsIgnoreCase(sid) && "ACCEPTED".equalsIgnoreCase(sr.status)) {
                    LocalDate d = LocalDate.parse(sr.swipeDate);
                    if (d.getMonthValue() == m && d.getYear() == y) {
                        totalSwipes++;
                        gross += sr.rateCharged;
                    }
                }
            }

            int rebateDays = 0;
            for (RebateRecord r : rebates) {
                if (r.studentId.equalsIgnoreCase(sid) && "APPROVED".equalsIgnoreCase(r.status)) {
                    LocalDate from = LocalDate.parse(r.fromDate);
                    LocalDate to = LocalDate.parse(r.toDate);
                    // calculate overlap in month
                    LocalDate startOfMonth = LocalDate.of(y, m, 1);
                    LocalDate endOfMonth = startOfMonth.plusMonths(1).minusDays(1);
                    LocalDate effFrom = from.isAfter(startOfMonth) ? from : startOfMonth;
                    LocalDate effTo = to.isBefore(endOfMonth) ? to : endOfMonth;
                    if (!effTo.isBefore(effFrom)) {
                        rebateDays += (effTo.toEpochDay() - effFrom.toEpochDay() + 1);
                    }
                }
            }

            double rebateCredit = rebateDays * 180.00;
            double netPayable = Math.max(0.00, gross - rebateCredit);

            // Upsert into bills list
            bills.removeIf(b -> b.studentId.equalsIgnoreCase(sid) && b.month == m && b.year == y);
            int bid = billIdSeq.incrementAndGet();
            BillRecord br = new BillRecord(bid, sid, m, y, totalSwipes, gross, rebateDays, rebateCredit, netPayable, "PENDING");
            bills.add(0, br);

            auditLogs.add(0, new AuditItem(auditIdSeq.incrementAndGet(), "BILLING_CALCULATED", "MONTHLY_BILLS", sid, null, "Gross=₹" + gross + "; RebateDays=" + rebateDays + "; Net=₹" + netPayable, "BILLING_ENGINE"));

            String resp = "{"
                    + "\"success\":true,"
                    + "\"billId\":" + bid + ","
                    + "\"studentId\":\"" + sid + "\","
                    + "\"month\":" + m + ","
                    + "\"year\":" + y + ","
                    + "\"totalSwipes\":" + totalSwipes + ","
                    + "\"grossAmount\":" + gross + ","
                    + "\"rebateDays\":" + rebateDays + ","
                    + "\"rebateCredit\":" + rebateCredit + ","
                    + "\"netPayable\":" + netPayable + ","
                    + "\"message\":\"Billing cursor process completed for " + m + "/" + y + ".\""
                    + "}";
            sendJsonResponse(ex, 200, resp);
        }
    }

    static class BillingHistoryHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            StringBuilder sb = new StringBuilder("[");
            int idx = 0;
            for (BillRecord b : bills) {
                if (idx++ > 0) sb.append(",");
                Boarder st = boarders.get(b.studentId);
                String sname = st != null ? st.name : b.studentId;
                sb.append("{")
                  .append("\"billId\":").append(b.billId).append(",")
                  .append("\"studentId\":\"").append(b.studentId).append("\",")
                  .append("\"studentName\":\"").append(escape(sname)).append("\",")
                  .append("\"month\":").append(b.month).append(",")
                  .append("\"year\":").append(b.year).append(",")
                  .append("\"totalSwipes\":").append(b.totalSwipes).append(",")
                  .append("\"grossAmount\":").append(b.grossAmount).append(",")
                  .append("\"rebateDays\":").append(b.rebateDays).append(",")
                  .append("\"rebateCredit\":").append(b.rebateCredit).append(",")
                  .append("\"netPayable\":").append(b.netPayable).append(",")
                  .append("\"paymentStatus\":\"").append(b.paymentStatus).append("\",")
                  .append("\"generatedAt\":\"").append(b.generatedAt).append("\"")
                  .append("}");
            }
            sb.append("]");
            sendJsonResponse(ex, 200, sb.toString());
        }
    }

    static class LedgerHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            StringBuilder sb = new StringBuilder("[");
            int idx = 0;
            for (Boarder b : boarders.values()) {
                if (idx++ > 0) sb.append(",");
                int swpCount = 0;
                double swpSpent = 0.0;
                for (SwipeRecord sr : swipes) {
                    if (sr.studentId.equalsIgnoreCase(b.studentId) && "ACCEPTED".equalsIgnoreCase(sr.status)) {
                        swpCount++;
                        swpSpent += sr.rateCharged;
                    }
                }
                int rebCount = 0;
                int rebDays = 0;
                for (RebateRecord rr : rebates) {
                    if (rr.studentId.equalsIgnoreCase(b.studentId) && "APPROVED".equalsIgnoreCase(rr.status)) {
                        rebCount++;
                        LocalDate f = LocalDate.parse(rr.fromDate);
                        LocalDate t = LocalDate.parse(rr.toDate);
                        rebDays += (t.toEpochDay() - f.toEpochDay() + 1);
                    }
                }

                sb.append("{")
                  .append("\"studentId\":\"").append(b.studentId).append("\",")
                  .append("\"name\":\"").append(escape(b.name)).append("\",")
                  .append("\"blockId\":\"").append(b.blockId).append("\",")
                  .append("\"roomNumber\":\"").append(b.roomNumber).append("\",")
                  .append("\"messType\":\"").append(b.messType).append("\",")
                  .append("\"walletBalance\":").append(b.walletBalance).append(",")
                  .append("\"totalSwipes\":").append(swpCount).append(",")
                  .append("\"totalExpenditure\":").append(swpSpent).append(",")
                  .append("\"approvedRebates\":").append(rebCount).append(",")
                  .append("\"rebateDays\":").append(rebDays)
                  .append("}");
            }
            sb.append("]");
            sendJsonResponse(ex, 200, sb.toString());
        }
    }

    static class AuditHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) { ex.sendResponseHeaders(204, -1); return; }

            StringBuilder sb = new StringBuilder("[");
            int idx = 0;
            for (AuditItem a : auditLogs) {
                if (idx++ > 0) sb.append(",");
                sb.append("{")
                  .append("\"logId\":").append(a.logId).append(",")
                  .append("\"actionType\":\"").append(a.actionType).append("\",")
                  .append("\"entityName\":\"").append(a.entityName).append("\",")
                  .append("\"entityId\":\"").append(a.entityId).append("\",")
                  .append("\"oldValue\":").append(a.oldValue != null ? "\"" + escape(a.oldValue) + "\"" : "null").append(",")
                  .append("\"newValue\":").append(a.newValue != null ? "\"" + escape(a.newValue) + "\"" : "null").append(",")
                  .append("\"performedBy\":\"").append(escape(a.performedBy)).append("\",")
                  .append("\"timestamp\":\"").append(a.timestamp).append("\"")
                  .append("}");
            }
            sb.append("]");
            sendJsonResponse(ex, 200, sb.toString());
        }
    }

    static class StaticFileHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            String path = ex.getRequestURI().getPath();
            if (path == null || path.equals("/") || path.isEmpty()) {
                path = "/index.html";
            }

            File f = new File("public" + path);
            if (!f.exists()) {
                f = new File(path.substring(1)); // try current dir
            }

            if (!f.exists() || f.isDirectory()) {
                f = new File("public/index.html");
            }

            if (!f.exists()) {
                byte[] notFound = "Portal UI ready. Please open index.html".getBytes(StandardCharsets.UTF_8);
                ex.sendResponseHeaders(404, notFound.length);
                OutputStream os = ex.getResponseBody();
                os.write(notFound);
                os.close();
                return;
            }

            String contentType = "text/html";
            if (f.getName().endsWith(".css")) contentType = "text/css";
            else if (f.getName().endsWith(".js")) contentType = "application/javascript";
            else if (f.getName().endsWith(".json")) contentType = "application/json";
            else if (f.getName().endsWith(".svg")) contentType = "image/svg+xml";

            ex.getResponseHeaders().set("Content-Type", contentType + "; charset=utf-8");
            ex.sendResponseHeaders(200, f.length());
            try (FileInputStream fis = new FileInputStream(f); OutputStream os = ex.getResponseBody()) {
                byte[] buf = new byte[8192];
                int n;
                while ((n = fis.read(buf)) > 0) {
                    os.write(buf, 0, n);
                }
            }
        }
    }

    // ------------------------------------------------------------------------
    // UTILITIES
    // ------------------------------------------------------------------------

    private static void addCorsHeaders(HttpExchange ex) {
        ex.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        ex.getResponseHeaders().set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        ex.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }

    private static void sendJsonResponse(HttpExchange ex, int code, String json) throws IOException {
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        ex.sendResponseHeaders(code, bytes.length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(bytes);
        }
    }

    private static String readBody(HttpExchange ex) throws IOException {
        try (InputStream is = ex.getRequestBody()) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] b = new byte[4096];
            int n;
            while ((n = is.read(b)) != -1) baos.write(b, 0, n);
            return baos.toString(StandardCharsets.UTF_8);
        }
    }

    private static Map<String, String> parseJsonSimple(String body) {
        Map<String, String> map = new HashMap<>();
        if (body == null || body.trim().isEmpty()) return map;
        String s = body.trim();
        if (s.startsWith("{")) s = s.substring(1);
        if (s.endsWith("}")) s = s.substring(0, s.length() - 1);

        String[] pairs = s.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
        for (String p : pairs) {
            String[] kv = p.split(":(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
            if (kv.length == 2) {
                String k = kv[0].trim().replaceAll("^\"|\"$", "");
                String v = kv[1].trim().replaceAll("^\"|\"$", "");
                map.put(k, v);
            }
        }
        return map;
    }

    private static Map<String, String> parseQuery(String q) {
        Map<String, String> map = new HashMap<>();
        if (q == null) return map;
        String[] pairs = q.split("&");
        for (String p : pairs) {
            String[] kv = p.split("=");
            if (kv.length == 2) {
                map.put(URLDecoder.decode(kv[0], StandardCharsets.UTF_8), URLDecoder.decode(kv[1], StandardCharsets.UTF_8));
            }
        }
        return map;
    }

    private static String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}
