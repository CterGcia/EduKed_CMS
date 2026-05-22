<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="dao.MySQLInstructorDAO" %>
<%@ page import="dao.DerbyUserDAO" %>
<%@ page import="model.Instructor" %>
<%@ page import="model.User" %>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Authentication & Access check
    if (session == null || session.getAttribute("username") == null) {
        response.sendRedirect("error_session.jsp");
        return;
    }

    String username = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("role");
    
    if (!"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("error_403.jsp");
        return;
    }

    // Fetch CRUD feedback messages
    String crudSuccessMessage = (String) session.getAttribute("crudSuccessMessage");
    String crudMessage = (String) session.getAttribute("crudMessage");
    if (crudSuccessMessage != null) session.removeAttribute("crudSuccessMessage");
    if (crudMessage != null) session.removeAttribute("crudMessage");

    MySQLInstructorDAO instructorDAO = new MySQLInstructorDAO();
    DerbyUserDAO userDAO = new DerbyUserDAO();
    List<Instructor> instructorList = null;
    List<User> userList = null;
    
    try {
        instructorList = instructorDAO.getAllInstructors();
        userList = userDAO.getAllUsers();
    } catch (Exception e) {
        throw new ServletException("Database error loading Faculty records", e);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - Faculty Registry</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .instructors-layout {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 1.5rem;
        }
        @media (max-width: 900px) {
            .instructors-layout {
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
        .search-container {
            margin-bottom: 1.5rem;
        }
        .search-input {
            width: 100%;
            background: var(--neo-surface);
            border: 1px solid var(--neo-border);
            color: var(--neo-text);
            font-family: var(--neo-mono);
            font-size: 0.85rem;
            padding: 0.6rem 0.8rem;
            outline: none;
        }
        .search-input:focus {
            border-color: var(--neo-cyan);
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
            <a href="students.jsp">Students</a>
            <a href="instructors.jsp" class="active">Instructors</a>
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
            <a href="dashboard.jsp">Console</a>
            <a href="courses.jsp">Course Catalog</a>
            <a href="students.jsp">Student Registry</a>
            <a href="instructors.jsp" class="active">Instructors List</a>
            <a href="users.jsp">System Users</a>
            <a href="reports.jsp">Report Center</a>
        </aside>

        <!-- Main Content -->
        <main class="neo-content">
            <div class="neo-section">
                <h1>Faculty Academic Registry</h1>
                <p>Verify instructor departments, associate profiles to user credentials, and trace active assignments.</p>
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

            <!-- Search Bar -->
            <div class="search-container">
                <input type="text" id="instructorSearch" class="search-input" placeholder="Search instructors by name, department, or assigned courses..." onkeyup="filterInstructors()">
            </div>

            <div class="instructors-layout">
                <!-- Left Side: Instructors Table -->
                <div>
                    <div class="neo-section">
                        <table class="admin-data-grid" id="instructorsTable">
                            <thead>
                                <tr>
                                    <th>Faculty ID</th>
                                    <th>Instructor Name</th>
                                    <th>Department</th>
                                    <th>Assigned Courses</th>
                                    <th style="width: 150px; text-align: center;">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (instructorList == null || instructorList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="5" class="no-data">No faculty records are registered.</td>
                                    </tr>
                                <% } else {
                                    for (Instructor i : instructorList) { %>
                                        <tr class="instructor-row">
                                            <td><%= i.getInstructorId() %></td>
                                            <td class="instructor-name-col"><%= i.getLastName() %>, <%= i.getFirstName() %></td>
                                            <td class="instructor-dept-col"><%= i.getDepartment() %></td>
                                            <td class="instructor-courses-col"><%= i.getCoursesTaught() %></td>
                                            <td style="text-align: center;">
                                                <div style="display: flex; gap: 0.3rem; justify-content: center;">
                                                    <button class="btn-action-primary" style="padding: 0.2rem 0.5rem;" 
                                                            onclick="editInstructor('<%= i.getInstructorId() %>', '<%= i.getLastName().replace("'", "\\'") %>', '<%= i.getFirstName().replace("'", "\\'") %>', '<%= i.getDepartment().replace("'", "\\'") %>', '')">EDIT</button>
                                                    <form action="${pageContext.request.contextPath}/InstructorServlet" method="POST" onsubmit="return confirm('Are you sure you want to delete instructor <%= i.getLastName() %>, <%= i.getFirstName() %>? Cascade logic will unassign courses.');" style="margin:0;">
                                                        <input type="hidden" name="action" value="delete">
                                                        <input type="hidden" name="instructorId" value="<%= i.getInstructorId() %>">
                                                        <button type="submit" class="btn-action-danger" style="padding: 0.2rem 0.5rem;">DELETE</button>
                                                    </form>
                                                </div>
                                            </td>
                                        </tr>
                                    <% }
                                } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Right Side: Forms -->
                <div>
                    <!-- Add Instructor -->
                    <div class="form-card" id="addInstructorSection">
                        <h3>Register Instructor</h3>
                        <form action="${pageContext.request.contextPath}/InstructorServlet" method="POST" class="neo-form">
                            <input type="hidden" name="action" value="add">
                            
                            <div class="neo-form-group">
                                <label for="lastName">Last Name</label>
                                <input type="text" id="lastName" name="lastName" placeholder="Enter last name" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="firstName">First Name</label>
                                <input type="text" id="firstName" name="firstName" placeholder="Enter first name" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="department">Department</label>
                                <input type="text" id="department" name="department" placeholder="e.g. Computer Science" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="userId">Linked System User</label>
                                <select id="userId" name="userId" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                    <option value="">-- Select Account Link (Optional) --</option>
                                    <% if (userList != null) {
                                        for (User u : userList) { %>
                                            <option value="<%= u.getUserId() %>"><%= u.getUsername() %> (<%= u.getRole().toUpperCase() %>)</option>
                                        <% }
                                    } %>
                                </select>
                            </div>
                            
                            <button type="submit" class="btn-action-primary" style="width: 100%;">REGISTER FACULTY</button>
                        </form>
                    </div>

                    <!-- Edit Instructor -->
                    <div class="form-card" id="editInstructorSection" style="display: none; border-color: var(--neo-cyan);">
                        <div style="display:flex; justify-content:space-between; align-items:center; border-bottom: 1px solid var(--neo-border); margin-bottom: 1rem; padding-bottom:0.5rem;">
                            <h3 style="margin-bottom:0; border:none;">Modify Instructor</h3>
                            <button class="btn-action-danger" style="padding: 0.1rem 0.4rem; font-size:0.7rem;" onclick="cancelEdit()">CLOSE</button>
                        </div>
                        <form action="${pageContext.request.contextPath}/InstructorServlet" method="POST" class="neo-form">
                            <input type="hidden" name="action" value="update">
                            <input type="hidden" id="editInstructorId" name="instructorId">
                            
                            <div class="neo-form-group">
                                <label for="editLastName">Last Name</label>
                                <input type="text" id="editLastName" name="lastName" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editFirstName">First Name</label>
                                <input type="text" id="editFirstName" name="firstName" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editDepartment">Department</label>
                                <input type="text" id="editDepartment" name="department" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editUserId">Linked System User</label>
                                <select id="editUserId" name="userId" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                    <option value="">-- Select Account Link (Optional) --</option>
                                    <% if (userList != null) {
                                        for (User u : userList) { %>
                                            <option value="<%= u.getUserId() %>"><%= u.getUsername() %> (<%= u.getRole().toUpperCase() %>)</option>
                                        <% }
                                    } %>
                                </select>
                            </div>
                            
                            <button type="submit" class="btn-action-primary" style="width: 100%;">UPDATE RECORD</button>
                        </form>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- Footer -->
    <footer class="neo-footer">
        <div>EduKed Course Management System // active learning, inc.</div>
        <div>Security Timeout: <span class="text-cyan">5 minutes</span></div>
    </footer>

    <script>
        function filterInstructors() {
            var input = document.getElementById("instructorSearch");
            var filter = input.value.toLowerCase();
            var rows = document.getElementsByClassName("instructor-row");
            
            for (var i = 0; i < rows.length; i++) {
                var name = rows[i].getElementsByClassName("instructor-name-col")[0].textContent.toLowerCase();
                var dept = rows[i].getElementsByClassName("instructor-dept-col")[0].textContent.toLowerCase();
                var courses = rows[i].getElementsByClassName("instructor-courses-col")[0].textContent.toLowerCase();
                
                if (name.indexOf(filter) > -1 || dept.indexOf(filter) > -1 || courses.indexOf(filter) > -1) {
                    rows[i].style.display = "";
                } else {
                    rows[i].style.display = "none";
                }
            }
        }

        function editInstructor(id, last, first, dept, linkedUserId) {
            document.getElementById("editInstructorId").value = id;
            document.getElementById("editLastName").value = last;
            document.getElementById("editFirstName").value = first;
            document.getElementById("editDepartment").value = dept;
            document.getElementById("editUserId").value = linkedUserId;
            
            document.getElementById("addInstructorSection").style.display = "none";
            document.getElementById("editInstructorSection").style.display = "block";
            
            document.getElementById("editInstructorSection").scrollIntoView({ behavior: 'smooth' });
        }

        function cancelEdit() {
            document.getElementById("editInstructorSection").style.display = "none";
            document.getElementById("addInstructorSection").style.display = "block";
        }
    </script>
</body>
</html>
