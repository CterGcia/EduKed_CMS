<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="dao.DerbyUserDAO" %>
<%@ page import="dao.MySQLCourseDAO" %>
<%@ page import="dao.MySQLStudentDAO" %>
<%@ page import="dao.MySQLInstructorDAO" %>
<%@ page import="dao.PostgreSQLAuditDAO" %>
<%@ page import="config.DatabaseConfig" %>
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
    
    // Initialize DAOs to fetch statistics
    DerbyUserDAO userDAO = new DerbyUserDAO();
    MySQLCourseDAO courseDAO = new MySQLCourseDAO();
    MySQLStudentDAO studentDAO = new MySQLStudentDAO();
    MySQLInstructorDAO instructorDAO = new MySQLInstructorDAO();
    PostgreSQLAuditDAO auditDAO = new PostgreSQLAuditDAO();
    
    int userCount = 0;
    int courseCount = 0;
    int studentCount = 0;
    int instructorCount = 0;
    int reportCount = 0;
    
    String derbyStatus = "OFFLINE";
    String mysqlStatus = "OFFLINE";
    String postgresStatus = "OFFLINE";
    
    // Check Derby and fetch count
    try {
        userCount = userDAO.getAllUsers().size();
        derbyStatus = "ONLINE";
    } catch (Exception e) {
        derbyStatus = "ERROR: " + e.getMessage();
    }
    
    // Check MySQL and fetch counts
    try {
        courseCount = courseDAO.getAllCourses().size();
        studentCount = studentDAO.getAllStudents().size();
        instructorCount = instructorDAO.getAllInstructors().size();
        mysqlStatus = "ONLINE";
    } catch (Exception e) {
        mysqlStatus = "ERROR: " + e.getMessage();
    }
    
    // Check PostgreSQL and fetch count
    try {
        reportCount = auditDAO.getReportLogs().size();
        postgresStatus = "ONLINE";
    } catch (Exception e) {
        postgresStatus = "ERROR: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - Dashboard</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .db-badge {
            font-family: var(--neo-mono);
            font-size: 0.75rem;
            padding: 0.2rem 0.5rem;
            border: 1px solid var(--neo-border);
            display: inline-block;
            margin-top: 0.5rem;
        }
        .db-online {
            background: rgba(0, 242, 254, 0.1);
            color: var(--neo-cyan);
            border-color: var(--neo-cyan);
        }
        .db-offline {
            background: rgba(255, 51, 102, 0.1);
            color: var(--neo-crimson);
            border-color: var(--neo-crimson);
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <header class="neo-navbar">
        <div class="neo-navbar-brand">EduKed CMS // active learning</div>
        <div class="neo-navbar-links">
            <a href="dashboard.jsp" class="active">Dashboard</a>
            <a href="courses.jsp">Courses</a>
            <% if ("admin".equalsIgnoreCase(role)) { %>
                <a href="students.jsp">Students</a>
                <a href="instructors.jsp">Instructors</a>
            <% } %>
            <a href="users.jsp">Users & Settings</a>
            <a href="reports.jsp">Reports</a>
            <a href="${pageContext.request.contextPath}/LogoutServlet" style="color: var(--neo-crimson);">LOGOUT</a>
        </div>
        <div class="neo-navbar-user">
            Logged in as: <span class="text-cyan"><%= username %></span> (<span class="mono"><%= role.toUpperCase() %></span>)
        </div>
    </header>

    <div class="neo-layout">
        <!-- Sidebar -->
        <aside class="neo-sidebar">
            <a href="dashboard.jsp" class="active">Console</a>
            <a href="courses.jsp">Course Catalog</a>
            <% if ("admin".equalsIgnoreCase(role)) { %>
                <a href="students.jsp">Student Registry</a>
                <a href="instructors.jsp">Instructors List</a>
            <% } %>
            <a href="users.jsp">System Users</a>
            <a href="reports.jsp">Report Center</a>
        </aside>

        <!-- Main Content -->
        <main class="neo-content">
            <div class="neo-section">
                <h1 class="mb-1">Operational Console</h1>
                <p>Welcome back, <%= username %>. Explore registries, build reports, and monitor system performance from here.</p>
            </div>

            <!-- Stats Grid -->
            <div class="neo-grid">
                <div class="neo-grid-cell">
                    <div class="label">System Accounts</div>
                    <div class="value"><%= userCount %></div>
                    <div class="sub">Auth (Derby DB)</div>
                </div>
                <div class="neo-grid-cell">
                    <div class="label">Active Courses</div>
                    <div class="value"><%= courseCount %></div>
                    <div class="sub">Registries (MySQL)</div>
                </div>
                <% if ("admin".equalsIgnoreCase(role)) { %>
                    <div class="neo-grid-cell">
                        <div class="label">Registered Students</div>
                        <div class="value"><%= studentCount %></div>
                        <div class="sub">Registries (MySQL)</div>
                    </div>
                    <div class="neo-grid-cell">
                        <div class="label">Faculty Members</div>
                        <div class="value"><%= instructorCount %></div>
                        <div class="sub">Registries (MySQL)</div>
                    </div>
                <% } %>
                <div class="neo-grid-cell">
                    <div class="label">Reports Compiled</div>
                    <div class="value"><%= reportCount %></div>
                    <div class="sub">Auditing (Postgres)</div>
                </div>
            </div>

            <!-- Database Connections View (Multi-DBMS status panel) -->
            <div class="neo-section mt-2">
                <h2 class="neo-section-title">Database Connectivity Matrix</h2>
                <div class="neo-grid">
                    <div class="neo-grid-cell">
                        <div class="label">Derby (Auth / Sessions)</div>
                        <div class="value" style="font-size: 1rem; margin-top: 0.5rem;">
                            <%= DatabaseConfig.derbyDriver != null ? "ClientDriver" : "Unloaded" %>
                        </div>
                        <div class="sub">
                            <%= DatabaseConfig.derbyUrl != null && DatabaseConfig.derbyUrl.length() > 30 ? DatabaseConfig.derbyUrl.substring(0, 30) + "..." : DatabaseConfig.derbyUrl %>
                        </div>
                        <div class="db-badge <%= derbyStatus.equals("ONLINE") ? "db-online" : "db-offline" %>">
                            STATUS: <%= derbyStatus %>
                        </div>
                    </div>
                    <div class="neo-grid-cell">
                        <div class="label">MySQL (Academic Registries)</div>
                        <div class="value" style="font-size: 1rem; margin-top: 0.5rem;">
                            <%= DatabaseConfig.mysqlDriver != null ? "MySQL Connector" : "Unloaded" %>
                        </div>
                        <div class="sub">
                            <%= DatabaseConfig.mysqlUrl != null && DatabaseConfig.mysqlUrl.length() > 30 ? DatabaseConfig.mysqlUrl.substring(0, 30) + "..." : DatabaseConfig.mysqlUrl %>
                        </div>
                        <div class="db-badge <%= mysqlStatus.equals("ONLINE") ? "db-online" : "db-offline" %>">
                            STATUS: <%= mysqlStatus %>
                        </div>
                    </div>
                    <div class="neo-grid-cell">
                        <div class="label">PostgreSQL (Audit / Error logs)</div>
                        <div class="value" style="font-size: 1rem; margin-top: 0.5rem;">
                            <%= DatabaseConfig.postgresDriver != null ? "PG Driver" : "Unloaded" %>
                        </div>
                        <div class="sub">
                            <%= DatabaseConfig.postgresUrl != null && DatabaseConfig.postgresUrl.length() > 30 ? DatabaseConfig.postgresUrl.substring(0, 30) + "..." : DatabaseConfig.postgresUrl %>
                        </div>
                        <div class="db-badge <%= postgresStatus.equals("ONLINE") ? "db-online" : "db-offline" %>">
                            STATUS: <%= postgresStatus %>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Quick Links -->
            <div class="neo-section">
                <h2 class="neo-section-title">Quick Tasks</h2>
                <div style="display: flex; gap: 1rem;">
                    <a href="courses.jsp" class="btn-action-primary">View Course Catalog</a>
                    <a href="reports.jsp" class="btn-action-primary">Assemble PDF Reports</a>
                    <a href="users.jsp" class="btn-action-primary">Update Profile Password</a>
                </div>
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
