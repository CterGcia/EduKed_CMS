<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="dao.DerbyUserDAO" %>
<%@ page import="model.User" %>
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

    DerbyUserDAO userDAO = new DerbyUserDAO();
    List<User> userList = null;
    if ("admin".equalsIgnoreCase(role)) {
        try {
            userList = userDAO.getAllUsers();
        } catch (Exception e) {
            // Forward database exception
            throw new ServletException("Failed to fetch user accounts", e);
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - User Accounts</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .users-layout {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 1.5rem;
        }
        @media (max-width: 900px) {
            .users-layout {
                grid-template-columns: 1fr;
            }
        }
        .form-card {
            background: var(--neo-surface);
            border: 1px solid var(--neo-border);
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .form-card h3 {
            border-bottom: 1px solid var(--neo-border);
            padding-bottom: 0.5rem;
            margin-bottom: 1rem;
            font-family: var(--neo-mono);
            font-size: 0.85rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .message-banner {
            border: 1px solid transparent;
            padding: 0.6rem 0.8rem;
            margin-bottom: 1.5rem;
            font-size: 0.85rem;
        }
        .success-banner {
            background: rgba(0, 242, 254, 0.1);
            border-color: var(--neo-cyan);
            color: var(--neo-cyan);
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
            <a href="users.jsp" class="active">Users & Settings</a>
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
            <a href="dashboard.jsp">Console</a>
            <a href="courses.jsp">Course Catalog</a>
            <% if ("admin".equalsIgnoreCase(role)) { %>
                <a href="students.jsp">Student Registry</a>
                <a href="instructors.jsp">Instructors List</a>
            <% } %>
            <a href="users.jsp" class="active">System Users</a>
            <a href="reports.jsp">Report Center</a>
        </aside>

        <!-- Main Content -->
        <main class="neo-content">
            <div class="neo-section">
                <h1>User Management & Security</h1>
                <p>Configure credentials, update account authorizations, and check system registries.</p>
            </div>

            <!-- Feedback Messages -->
            <% if (crudSuccessMessage != null && !crudSuccessMessage.trim().isEmpty()) { %>
                <div class="message-banner success-banner">
                    <%= crudSuccessMessage %>
                </div>
            <% } %>
            <% if (crudMessage != null && !crudMessage.trim().isEmpty()) { %>
                <div class="message-banner error-banner">
                    <%= crudMessage %>
                </div>
            <% } %>

            <div class="users-layout">
                <!-- Left Side: User Registry Table (Admin only) -->
                <div>
                    <% if ("admin".equalsIgnoreCase(role)) { %>
                        <div class="neo-section">
                            <h2 class="neo-section-title">System User Registry</h2>
                            <table class="admin-data-grid">
                                <thead>
                                    <tr>
                                        <th>User ID</th>
                                        <th>Username</th>
                                        <th>Role</th>
                                        <th>Created At</th>
                                        <th style="width: 150px; text-align: center;">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (userList == null || userList.isEmpty()) { %>
                                        <tr>
                                            <td colspan="5" class="no-data">No accounts registered in system.</td>
                                        </tr>
                                    <% } else {
                                        for (User u : userList) { %>
                                            <tr>
                                                <td><%= u.getUserId() %></td>
                                                <td>
                                                    <%= u.getUsername() %>
                                                    <% if (u.getUsername().equals(username)) { %>
                                                        <span class="text-cyan">* (You)</span>
                                                    <% } %>
                                                </td>
                                                <td>
                                                    <span class="<%= "admin".equalsIgnoreCase(u.getRole()) ? "status-admin" : "status-guest" %>">
                                                        <%= u.getRole().toUpperCase() %>
                                                    </span>
                                                </td>
                                                <td><%= u.getCreatedAt() != null ? u.getCreatedAt().toString() : "N/A" %></td>
                                                <td style="text-align: center;">
                                                    <div style="display: flex; gap: 0.3rem; justify-content: center;">
                                                        <button class="btn-action-primary" style="padding: 0.2rem 0.5rem;" onclick="editUser('<%= u.getUsername() %>', '<%= u.getRole() %>')">EDIT</button>
                                                        <% if (!u.getUsername().equals(username)) { %>
                                                            <form action="${pageContext.request.contextPath}/UserServlet" method="POST" onsubmit="return confirm('Are you sure you want to delete user <%= u.getUsername() %>? This will also remove their session logs.');" style="margin:0;">
                                                                <input type="hidden" name="action" value="delete">
                                                                <input type="hidden" name="deleteUsername" value="<%= u.getUsername() %>">
                                                                <button type="submit" class="btn-action-danger" style="padding: 0.2rem 0.5rem;">DELETE</button>
                                                            </form>
                                                        <% } else { %>
                                                            <span class="text-muted" style="font-size:0.7rem; padding: 0.2rem;">LOCKED</span>
                                                        <% } %>
                                                    </div>
                                                </td>
                                            </tr>
                                        <% } 
                                    } %>
                                </tbody>
                            </table>
                        </div>
                    <% } else { %>
                        <div class="form-card">
                            <h3>Access Control Restrictions</h3>
                            <p>You are logged in as a <strong>Guest</strong>. Academic registries and user directory lists are restricted. If you need elevated access, contact an IT Administrator.</p>
                        </div>
                    <% } %>
                </div>

                <!-- Right Side: Forms (Self-Service Password + Admin Forms) -->
                <div>
                    <!-- Section: Self-Service Password -->
                    <div class="form-card">
                        <h3>Update Your Password</h3>
                        <form action="${pageContext.request.contextPath}/UserServlet" method="POST" class="neo-form">
                            <input type="hidden" name="action" value="changePassword">
                            
                            <div class="neo-form-group">
                                <label for="oldPassword">Current Password</label>
                                <input type="password" id="oldPassword" name="oldPassword" placeholder="Enter current password" required>
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="newPassword">New Password</label>
                                <input type="password" id="newPassword" name="newPassword" placeholder="Enter new password" required>
                            </div>
                            
                            <button type="submit" class="btn-action-primary" style="width: 100%;">CHANGE PASSWORD</button>
                        </form>
                    </div>

                    <!-- Sections: Admin CRUD Forms -->
                    <% if ("admin".equalsIgnoreCase(role)) { %>
                        <!-- Form 1: Add User -->
                        <div class="form-card" id="addUserSection">
                            <h3>Register New User Account</h3>
                            <form action="${pageContext.request.contextPath}/UserServlet" method="POST" class="neo-form">
                                <input type="hidden" name="action" value="add">
                                
                                <div class="neo-form-group">
                                    <label for="newUsername">Username</label>
                                    <input type="text" id="newUsername" name="newUsername" placeholder="Enter new username" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="newPassword">Password</label>
                                    <input type="password" id="newPassword" name="newPassword" placeholder="Enter temporary password" required>
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="newRole">Role</label>
                                    <select id="newRole" name="newRole" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="guest">Guest</option>
                                        <option value="admin">Admin</option>
                                    </select>
                                </div>
                                
                                <button type="submit" class="btn-action-primary" style="width: 100%;">ADD USER ACCOUNT</button>
                            </form>
                        </div>

                        <!-- Form 2: Edit User (Hidden until Edit is clicked) -->
                        <div class="form-card" id="editUserSection" style="display: none; border-color: var(--neo-cyan);">
                            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom: 1px solid var(--neo-border); margin-bottom: 1rem; padding-bottom:0.5rem;">
                                <h3 style="margin-bottom:0; border:none;">Modify Account</h3>
                                <button class="btn-action-danger" style="padding: 0.1rem 0.4rem; font-size:0.7rem;" onclick="cancelEdit()">CLOSE</button>
                            </div>
                            <form action="${pageContext.request.contextPath}/UserServlet" method="POST" class="neo-form">
                                <input type="hidden" name="action" value="update">
                                <input type="hidden" id="editUsernameHidden" name="editUsername">
                                
                                <div class="neo-form-group">
                                    <label>Username</label>
                                    <input type="text" id="editUsernameDisplay" disabled style="opacity: 0.6;">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editPassword">Password <span class="text-muted" style="font-size:0.7rem;">(Leave blank to keep current)</span></label>
                                    <input type="password" id="editPassword" name="editPassword" placeholder="Enter new password (optional)">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editRole">Role</label>
                                    <select id="editRole" name="editRole" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="guest">Guest</option>
                                        <option value="admin">Admin</option>
                                    </select>
                                </div>
                                
                                <button type="submit" class="btn-action-primary" style="width: 100%;">UPDATE ACCOUNT</button>
                            </form>
                        </div>
                    <% } %>
                </div>
            </div>
        </main>
    </div>

    <!-- Footer -->
    <footer class="neo-footer">
        <div>EduKed Course Management System // active learning, inc.</div>
        <div>Security Timeout: <span class="text-cyan">5 minutes</span></div>
    </footer>

    <% if ("admin".equalsIgnoreCase(role)) { %>
        <script>
            function editUser(username, role) {
                // Populate and display the edit user form card
                document.getElementById("editUsernameHidden").value = username;
                document.getElementById("editUsernameDisplay").value = username;
                document.getElementById("editRole").value = role.toLowerCase();
                document.getElementById("editPassword").value = "";
                
                document.getElementById("addUserSection").style.display = "none";
                document.getElementById("editUserSection").style.display = "block";
                
                // Scroll to edit form
                document.getElementById("editUserSection").scrollIntoView({ behavior: 'smooth' });
            }

            function cancelEdit() {
                document.getElementById("editUserSection").style.display = "none";
                document.getElementById("addUserSection").style.display = "block";
            }
        </script>
    <% } %>
</body>
</html>
