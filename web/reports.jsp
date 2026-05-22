<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="dao.PostgreSQLAuditDAO" %>
<%@ page import="dao.PostgreSQLErrorDAO" %>
<%@ page import="model.ReportLog" %>
<%@ page import="model.ErrorLog" %>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Authentication check
    if (session == null || session.getAttribute("username") == null) {
        response.sendRedirect("error_session.jsp");
        return;
    }

    String username = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("role");
    
    // Fetch CRUD feedback messages
    String crudSuccessMessage = (String) session.getAttribute("crudSuccessMessage");
    String crudMessage = (String) session.getAttribute("crudMessage");
    if (crudSuccessMessage != null) session.removeAttribute("crudSuccessMessage");
    if (crudMessage != null) session.removeAttribute("crudMessage");

    PostgreSQLAuditDAO auditDAO = new PostgreSQLAuditDAO();
    PostgreSQLErrorDAO errorDAO = new PostgreSQLErrorDAO();
    List<ReportLog> recentReportLogs = null;
    List<ErrorLog> recentErrorLogs = null;
    
    // Only admins can inspect DB audit logs
    if ("admin".equalsIgnoreCase(role)) {
        try {
            recentReportLogs = auditDAO.getReportLogs();
            recentErrorLogs = errorDAO.getErrorLogs();
        } catch (Exception e) {
            // Log fallback if PG is down
            System.err.println("Failed to fetch reports/errors log history boards: " + e.getMessage());
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - Report Center</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .reports-layout {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1.5rem;
        }
        @media (max-width: 900px) {
            .reports-layout {
                grid-template-columns: 1fr;
            }
        }
        .report-card {
            background: var(--neo-surface);
            border: 1px solid var(--neo-border);
            padding: 1.5rem;
            margin-bottom: 1rem;
        }
        .report-card h3 {
            font-family: var(--neo-mono);
            font-size: 0.9rem;
            color: var(--neo-cyan);
            margin-bottom: 0.5rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .report-card p {
            font-size: 0.85rem;
            margin-bottom: 1.2rem;
        }
        .form-inline-group {
            display: flex;
            gap: 0.8rem;
            flex-wrap: wrap;
        }
        .form-inline-group input, .form-inline-group select {
            background: var(--neo-surface);
            border: 1px solid var(--neo-border);
            color: var(--neo-text);
            font-family: var(--neo-mono);
            font-size: 0.8rem;
            padding: 0.5rem 0.7rem;
            outline: none;
        }
        .form-inline-group input:focus, .form-inline-group select:focus {
            border-color: var(--neo-cyan);
        }
        .message-banner {
            border: 1px solid transparent;
            padding: 0.6rem 0.8rem;
            margin-bottom: 1.5rem;
            font-size: 0.85rem;
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <header class="neo-navbar">
        <div class="neo-navbar-brand">EduKed CMS // active learning</div>
        <div class="neo-navbar-links">
            <a href="dashboard.jsp">Dashboard</a>
            <a href="courses.jsp">Courses</a>
            <% if ("admin".equalsIgnoreCase(role)) { %>
                <a href="students.jsp">Students</a>
                <a href="instructors.jsp">Instructors</a>
            <% } %>
            <a href="users.jsp">Users & Settings</a>
            <a href="reports.jsp" class="active">Reports</a>
            <a href="${pageContext.request.contextPath}/LogoutServlet" style="color: var(--neo-crimson);">LOGOUT</a>
        </div>
        <div class="neo-navbar-user">
            Logged in as: <span class="text-cyan"><%= username %></span> (<span class="mono"><%= role.toUpperCase() %></span>)
        </div>
    </header>

    <div class="neo-layout">
        <!-- Sidebar -->
        <aside class="neo-sidebar">
            <a href="dashboard.jsp">Console</a>
            <a href="courses.jsp">Course Catalog</a>
            <% if ("admin".equalsIgnoreCase(role)) { %>
                <a href="students.jsp">Student Registry</a>
                <a href="instructors.jsp">Instructors List</a>
            <% } %>
            <a href="users.jsp">System Users</a>
            <a href="reports.jsp" class="active">Report Center</a>
        </aside>

        <!-- Main Content -->
        <main class="neo-content">
            <div class="neo-section">
                <h1>Academic Report Assembly Center</h1>
                <p>Compile database inventory lists, export active sessions history, and query time-bound error audits.</p>
            </div>

            <!-- Feedback Messages -->
            <% if (crudSuccessMessage != null && !crudSuccessMessage.trim().isEmpty()) { %>
                <div class="message-banner success-banner" style="background: rgba(0, 242, 254, 0.1); border-color: var(--neo-cyan); color: var(--neo-cyan);">
                    <%= crudSuccessMessage %>
                </div>
            <% } %>
            <% if (crudMessage != null && !crudMessage.trim().isEmpty()) { %>
                <div class="message-banner error-banner" style="background: rgba(255, 51, 102, 0.1); border-color: var(--neo-crimson); color: var(--neo-crimson);">
                    <%= crudMessage %>
                </div>
            <% } %>

            <div class="reports-layout">
                <!-- Left Column: Report Options -->
                <div>
                    <h2 class="neo-section-title">Available Document Assemblies</h2>
                    
                    <!-- Report 1: Course Catalog (Available to ALL) -->
                    <div class="report-card">
                        <h3>1. Academic Course Catalog Report</h3>
                        <p>Generates a list of all course offerings including scheduling parameters, rooms, and instructor associations from the MySQL business databases.</p>
                        <form action="${pageContext.request.contextPath}/ReportServlet" method="POST" target="_blank">
                            <input type="hidden" name="reportType" value="COURSE_CATALOG">
                            <button type="submit" class="btn-action-primary">ASSEMBLE DRAFT (PDF)</button>
                        </form>
                    </div>

                    <% if ("admin".equalsIgnoreCase(role)) { %>
                        <!-- Report 2: All Users (Admin Only) -->
                        <div class="report-card">
                            <h3>2. System User Registry Report</h3>
                            <p>Compiles all system login accounts, roles, and registration dates from Derby. For security, passwords are omitted. Your current session profile is appended with an asterisk (*).</p>
                            <form action="${pageContext.request.contextPath}/ReportServlet" method="POST" target="_blank">
                                <input type="hidden" name="reportType" value="ALL_RECORDS">
                                <button type="submit" class="btn-action-primary">ASSEMBLE REPORT (PDF)</button>
                            </form>
                        </div>

                        <!-- Report 3: Own Records (Admin Only) -->
                        <div class="report-card">
                            <h3>3. Admin Session Logs Report</h3>
                            <p>Generates a detailed summary of your login and logout events. Inactive, timeout, and active sessions are tracked to evaluate operational safety metrics.</p>
                            <form action="${pageContext.request.contextPath}/ReportServlet" method="POST" target="_blank">
                                <input type="hidden" name="reportType" value="OWN_RECORDS">
                                <button type="submit" class="btn-action-primary">ASSEMBLE REPORT (PDF)</button>
                            </form>
                        </div>

                        <!-- Report 4: Time-Bound Report (Admin Only) -->
                        <div class="report-card" style="border-color: var(--neo-cyan);">
                            <h3>4. Time-Bound Audit Logs Report</h3>
                            <p>Queries PostgreSQL auditing logs inside a specific date-time window. Renders a warning cell in the PDF if no events are captured in the specified range.</p>
                            <form action="${pageContext.request.contextPath}/ReportServlet" method="POST" target="_blank" class="neo-form">
                                <input type="hidden" name="reportType" value="TIME_BOUND">
                                
                                <div class="neo-form-group">
                                    <label for="startDate">Start Date/Time</label>
                                    <input type="datetime-local" id="startDate" name="startDate" required style="width:100%;">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="endDate">End Date/Time</label>
                                    <input type="datetime-local" id="endDate" name="endDate" required style="width:100%;">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="logSource">Audit Logging Source</label>
                                    <select id="logSource" name="logSource" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="ReportLogs">Report Generation Audits (ReportLogs)</option>
                                        <option value="ErrorLogs">System Crash Logs (ErrorLogs)</option>
                                    </select>
                                </div>
                                
                                <button type="submit" class="btn-action-primary" style="width:100%;">COMPILE AUDIT LOGS (PDF)</button>
                            </form>
                        </div>

                        <!-- Report 5: Time-Bound Users Created (Admin Only) -->
                        <div class="report-card" style="border-color: var(--neo-border);">
                            <h3>5. Time-Bound User Creation Report</h3>
                            <p>Builds a Derby user registry report filtered by account creation timestamp (USERS.created_at) within a selected date-time interval.</p>
                            <form action="${pageContext.request.contextPath}/ReportServlet" method="POST" target="_blank" class="neo-form">
                                <input type="hidden" name="reportType" value="TIME_BOUND_USERS">

                                <div class="neo-form-group">
                                    <label for="userStartDate">Start Date/Time</label>
                                    <input type="datetime-local" id="userStartDate" name="startDate" required style="width:100%;">
                                </div>

                                <div class="neo-form-group">
                                    <label for="userEndDate">End Date/Time</label>
                                    <input type="datetime-local" id="userEndDate" name="endDate" required style="width:100%;">
                                </div>

                                <button type="submit" class="btn-action-primary" style="width:100%;">COMPILE USER CREATION REPORT (PDF)</button>
                            </form>
                        </div>
                    <% } %>
                </div>

                <!-- Right Column: Auditing Log History Boards (Admins only) -->
                <% if ("admin".equalsIgnoreCase(role)) { %>
                    <div>
                        <h2 class="neo-section-title">Operational Audits Trail (PostgreSql)</h2>
                        
                        <!-- Reports History Board -->
                        <div class="neo-section">
                            <h3 class="mono" style="font-size:0.8rem; margin-bottom:0.5rem; text-transform:uppercase; color: var(--neo-muted);">Recent PDF Creations</h3>
                            <table class="admin-data-grid" style="font-size:0.75rem;">
                                <thead>
                                    <tr>
                                        <th>By</th>
                                        <th>Type</th>
                                        <th>Filename</th>
                                        <th>Generated At</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (recentReportLogs == null || recentReportLogs.isEmpty()) { %>
                                        <tr>
                                            <td colspan="4" class="no-data">No report creations logged.</td>
                                        </tr>
                                    <% } else {
                                        int count = 0;
                                        for (ReportLog rl : recentReportLogs) {
                                            if (count++ >= 8) break; // Limit to recent 8 records
                                            %>
                                            <tr>
                                                <td><%= rl.getGeneratedBy() %></td>
                                                <td><%= rl.getReportType() %></td>
                                                <td><%= rl.getFilename() %></td>
                                                <td><%= rl.getGeneratedAt() != null ? rl.getGeneratedAt().toString() : "N/A" %></td>
                                            </tr>
                                        <% }
                                    } %>
                                </tbody>
                            </table>
                        </div>

                        <!-- System Error Board -->
                        <div class="neo-section mt-2">
                            <h3 class="mono" style="font-size:0.8rem; margin-bottom:0.5rem; text-transform:uppercase; color: var(--neo-crimson);">Recent System Errors</h3>
                            <table class="admin-data-grid" style="font-size:0.75rem;">
                                <thead>
                                    <tr>
                                        <th>Code</th>
                                        <th>Message</th>
                                        <th>Timestamp</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (recentErrorLogs == null || recentErrorLogs.isEmpty()) { %>
                                        <tr>
                                            <td colspan="3" class="no-data">No system crashes logged.</td>
                                        </tr>
                                    <% } else {
                                        int count = 0;
                                        for (ErrorLog el : recentErrorLogs) {
                                            if (count++ >= 8) break; // Limit to recent 8 records
                                            %>
                                            <tr>
                                                <td class="text-danger"><%= el.getErrorCode() %></td>
                                                <td><%= el.getMessage() != null && el.getMessage().length() > 50 ? el.getMessage().substring(0,47) + "..." : el.getMessage() %></td>
                                                <td><%= el.getTimestamp() != null ? el.getTimestamp().toString() : "N/A" %></td>
                                            </tr>
                                        <% }
                                    } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                <% } %>
            </div>
        </main>
    </div>

    <!-- Footer -->
    <footer class="neo-footer">
        <div>EduKed Course Management System // active learning, inc.</div>
        <div>Security Timeout: <span class="text-cyan">5 minutes</span></div>
    </footer>
</body>
</html>
