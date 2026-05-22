<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="config.DatabaseConfig" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    
    class DBStatus {
        String dbName;
        boolean connected;
        String message;
        List<String> details = new ArrayList<String>();
    }
    
    DBStatus derbyStatus = new DBStatus();
    derbyStatus.dbName = "Apache Derby (Auth & Sessions)";
    try {
        if (DatabaseConfig.derbyUrl == null) {
            derbyStatus.connected = false;
            derbyStatus.message = "DatabaseConfig derbyUrl is null. Has context listener initialized?";
        } else {
            Class.forName(DatabaseConfig.derbyDriver != null ? DatabaseConfig.derbyDriver : "org.apache.derby.jdbc.ClientDriver");
            try (Connection conn = DriverManager.getConnection(DatabaseConfig.derbyUrl)) {
                derbyStatus.connected = true;
                derbyStatus.message = "Successfully connected to Derby at: " + DatabaseConfig.derbyUrl;
                
                // Check Users table
                DatabaseMetaData dbmd = conn.getMetaData();
                boolean usersExists = false;
                try (ResultSet rs = dbmd.getTables(null, null, "USERS", null)) {
                    if (rs.next()) usersExists = true;
                }
                if (!usersExists) {
                    try (ResultSet rs = dbmd.getTables(null, null, "users", null)) {
                        if (rs.next()) usersExists = true;
                    }
                }
                
                derbyStatus.details.add("Table USERS exists: " + usersExists);
                if (usersExists) {
                    try (Statement stmt = conn.createStatement();
                         ResultSet rs = stmt.executeQuery("SELECT user_id, username, role FROM Users ORDER BY user_id")) {
                        int count = 0;
                        while (rs.next()) {
                            count++;
                            if (count <= 10) {
                                derbyStatus.details.add("User #" + rs.getInt("user_id") + ": username='" + rs.getString("username") + "', role='" + rs.getString("role") + "'");
                            }
                        }
                        derbyStatus.details.add("Total users in database: " + count);
                    } catch (SQLException e) {
                        derbyStatus.details.add("Error querying Users table: " + e.getMessage());
                    }
                }
            }
        }
    } catch (Exception e) {
        derbyStatus.connected = false;
        derbyStatus.message = "Connection failed: " + e.toString();
    }
    
    DBStatus mysqlStatus = new DBStatus();
    mysqlStatus.dbName = "MySQL 8.0 (Academic Registries)";
    try {
        if (DatabaseConfig.mysqlUrl == null) {
            mysqlStatus.connected = false;
            mysqlStatus.message = "DatabaseConfig mysqlUrl is null. Has context listener initialized?";
        } else {
            Class.forName(DatabaseConfig.mysqlDriver != null ? DatabaseConfig.mysqlDriver : "com.mysql.cj.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(DatabaseConfig.mysqlUrl, DatabaseConfig.mysqlUser, DatabaseConfig.mysqlPassword)) {
                mysqlStatus.connected = true;
                mysqlStatus.message = "Successfully connected to MySQL at: " + DatabaseConfig.mysqlUrl;
                
                // Query counts
                try (Statement stmt = conn.createStatement()) {
                    try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM Semesters")) {
                        if (rs.next()) mysqlStatus.details.add("Semesters count: " + rs.getInt(1));
                    }
                    try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM Courses")) {
                        if (rs.next()) mysqlStatus.details.add("Courses count: " + rs.getInt(1));
                    }
                    try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM Students")) {
                        if (rs.next()) mysqlStatus.details.add("Students count: " + rs.getInt(1));
                    }
                    try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM Instructors")) {
                        if (rs.next()) mysqlStatus.details.add("Instructors count: " + rs.getInt(1));
                    }
                } catch (SQLException e) {
                    mysqlStatus.details.add("Error querying MySQL tables: " + e.getMessage());
                }
            }
        }
    } catch (Exception e) {
        mysqlStatus.connected = false;
        mysqlStatus.message = "Connection failed: " + e.toString();
    }
    
    DBStatus postgresStatus = new DBStatus();
    postgresStatus.dbName = "PostgreSQL (Logs & Audits)";
    try {
        if (DatabaseConfig.postgresUrl == null) {
            postgresStatus.connected = false;
            postgresStatus.message = "DatabaseConfig postgresUrl is null. Has context listener initialized?";
        } else {
            Class.forName(DatabaseConfig.postgresDriver != null ? DatabaseConfig.postgresDriver : "org.postgresql.Driver");
            try (Connection conn = DriverManager.getConnection(DatabaseConfig.postgresUrl, DatabaseConfig.postgresUser, DatabaseConfig.postgresPassword)) {
                postgresStatus.connected = true;
                postgresStatus.message = "Successfully connected to PostgreSQL at: " + DatabaseConfig.postgresUrl;
                
                try (Statement stmt = conn.createStatement()) {
                    try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM ReportLogs")) {
                        if (rs.next()) postgresStatus.details.add("ReportLogs count: " + rs.getInt(1));
                    }
                    try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM ErrorLogs")) {
                        if (rs.next()) postgresStatus.details.add("ErrorLogs count: " + rs.getInt(1));
                    }
                } catch (SQLException e) {
                    postgresStatus.details.add("Error querying PostgreSQL tables: " + e.getMessage());
                }
            }
        }
    } catch (Exception e) {
        postgresStatus.connected = false;
        postgresStatus.message = "Connection failed: " + e.toString();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - DB Diagnostics</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .diag-container {
            max-width: 800px;
            margin: 2rem auto;
            padding: 1rem;
        }
        .diag-card {
            background: var(--neo-surface);
            border: 2px solid var(--neo-text) !important;
            box-shadow: 6px 6px 0px 0px var(--neo-text);
            margin-bottom: 2rem;
            padding: 1.5rem;
        }
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            font-weight: bold;
            text-transform: uppercase;
            font-size: 0.8rem;
            border: 2px solid var(--neo-text);
            margin-bottom: 0.5rem;
        }
        .status-ok {
            background-color: var(--neo-green);
            color: var(--neo-text);
        }
        .status-fail {
            background-color: var(--neo-crimson);
            color: white;
        }
        .diag-title {
            font-family: 'JetBrains Mono', monospace;
            font-size: 1.2rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
        }
        .details-list {
            list-style: none;
            padding-left: 0;
            margin-top: 1rem;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.85rem;
            background: #f0f0f0;
            border: 1px solid var(--neo-text);
            padding: 0.75rem;
        }
        .details-list li {
            margin-bottom: 0.25rem;
            border-bottom: 1px dashed #ccc;
            padding-bottom: 0.25rem;
        }
        .details-list li:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
        }
    </style>
</head>
<body>
    <div class="diag-container">
        <h1 style="font-family: 'JetBrains Mono', monospace; margin-bottom: 1rem;">System Database Diagnostics</h1>
        <p style="margin-bottom: 2rem;">Load this page to examine the connection health and content seeding status of the multi-database setup.</p>
        
        <!-- Derby -->
        <div class="diag-card">
            <div class="status-badge <%= derbyStatus.connected ? "status-ok" : "status-fail" %>">
                <%= derbyStatus.connected ? "CONNECTED" : "FAILED" %>
            </div>
            <div class="diag-title">// <%= derbyStatus.dbName %></div>
            <p><%= derbyStatus.message %></p>
            <% if (!derbyStatus.details.isEmpty()) { %>
                <ul class="details-list">
                    <% for (String detail : derbyStatus.details) { %>
                        <li><%= detail %></li>
                    <% } %>
                </ul>
            <% } %>
        </div>

        <!-- MySQL -->
        <div class="diag-card">
            <div class="status-badge <%= mysqlStatus.connected ? "status-ok" : "status-fail" %>">
                <%= mysqlStatus.connected ? "CONNECTED" : "FAILED" %>
            </div>
            <div class="diag-title">// <%= mysqlStatus.dbName %></div>
            <p><%= mysqlStatus.message %></p>
            <% if (!mysqlStatus.details.isEmpty()) { %>
                <ul class="details-list">
                    <% for (String detail : mysqlStatus.details) { %>
                        <li><%= detail %></li>
                    <% } %>
                </ul>
            <% } %>
        </div>

        <!-- PostgreSQL -->
        <div class="diag-card">
            <div class="status-badge <%= postgresStatus.connected ? "status-ok" : "status-fail" %>">
                <%= postgresStatus.connected ? "CONNECTED" : "FAILED" %>
            </div>
            <div class="diag-title">// <%= postgresStatus.dbName %></div>
            <p><%= postgresStatus.message %></p>
            <% if (!postgresStatus.details.isEmpty()) { %>
                <ul class="details-list">
                    <% for (String detail : postgresStatus.details) { %>
                        <li><%= detail %></li>
                    <% } %>
                </ul>
            <% } %>
        </div>
        
        <a href="index.jsp" class="btn-action-primary">Return to Login Screen</a>
    </div>
</body>
</html>
