<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="dao.MySQLStudentDAO" %>
<%@ page import="model.Student" %>
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

    MySQLStudentDAO studentDAO = new MySQLStudentDAO();
    List<Student> studentList = null;
    
    try {
        studentList = studentDAO.getAllStudents();
    } catch (Exception e) {
        throw new ServletException("Database error loading Student records", e);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - Student Registry</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .students-layout {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 1.5rem;
        }
        @media (max-width: 900px) {
            .students-layout {
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
            <a href="students.jsp" class="active">Students</a>
            <a href="instructors.jsp">Instructors</a>
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
            <a href="students.jsp" class="active">Student Registry</a>
            <a href="instructors.jsp">Instructors List</a>
            <a href="users.jsp">System Users</a>
            <a href="reports.jsp">Report Center</a>
        </aside>

        <!-- Main Content -->
        <main class="neo-content">
            <div class="neo-section">
                <h1>Student Academic Registry</h1>
                <p>Register new student profiles, search enrollment details, and verify active programmatic streams.</p>
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
                <input type="text" id="studentSearch" class="search-input" placeholder="Search students by student number, name, program, or email..." onkeyup="filterStudents()">
            </div>

            <div class="students-layout">
                <!-- Left Side: Students Table -->
                <div>
                    <div class="neo-section">
                        <table class="admin-data-grid" id="studentsTable">
                            <thead>
                                <tr>
                                    <th>Student ID</th>
                                    <th>Student No</th>
                                    <th>Student Name</th>
                                    <th>Email</th>
                                    <th>Year</th>
                                    <th>Program</th>
                                    <th style="width: 150px; text-align: center;">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (studentList == null || studentList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="7" class="no-data">No students are currently registered.</td>
                                    </tr>
                                <% } else {
                                    for (Student s : studentList) { %>
                                        <tr class="student-row">
                                            <td><%= s.getStudentId() %></td>
                                            <td class="student-no-col"><%= s.getStudentNo() %></td>
                                            <td class="student-name-col"><%= s.getStudentName() %></td>
                                            <td class="student-email-col"><%= s.getEmail() %></td>
                                            <td><%= s.getYearLevel() %></td>
                                            <td class="student-prog-col"><%= s.getProgram() %></td>
                                            <td style="text-align: center;">
                                                <div style="display: flex; gap: 0.3rem; justify-content: center;">
                                                    <button class="btn-action-primary" style="padding: 0.2rem 0.5rem;" 
                                                            onclick="editStudent('<%= s.getStudentId() %>', '<%= s.getStudentNo() %>', '<%= s.getLastName().replace("'", "\\'") %>', '<%= s.getFirstName().replace("'", "\\'") %>', '<%= s.getEmail().replace("'", "\\'") %>', '<%= s.getYearLevel() %>', '<%= s.getProgram() %>')">EDIT</button>
                                                    <form action="${pageContext.request.contextPath}/StudentServlet" method="POST" onsubmit="return confirm('Are you sure you want to delete student <%= s.getStudentNo() %>?');" style="margin:0;">
                                                        <input type="hidden" name="action" value="delete">
                                                        <input type="hidden" name="studentId" value="<%= s.getStudentId() %>">
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
                    <!-- Add Student -->
                    <div class="form-card" id="addStudentSection">
                        <h3>Register Student</h3>
                        <form action="${pageContext.request.contextPath}/StudentServlet" method="POST" class="neo-form">
                            <input type="hidden" name="action" value="add">
                            
                            <div class="neo-form-group">
                                <label for="studentNo">Student Number</label>
                                <input type="text" id="studentNo" name="studentNo" placeholder="e.g. 2021-00001" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="lastName">Last Name</label>
                                <input type="text" id="lastName" name="lastName" placeholder="Enter last name" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="firstName">First Name</label>
                                <input type="text" id="firstName" name="firstName" placeholder="Enter first name" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="email">Email</label>
                                <input type="text" id="email" name="email" placeholder="e.g. name@student.edu" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="yearLevel">Year Level</label>
                                <select id="yearLevel" name="yearLevel" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                    <option value="1">1st Year</option>
                                    <option value="2">2nd Year</option>
                                    <option value="3">3rd Year</option>
                                    <option value="4">4th Year</option>
                                </select>
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="program">Program</label>
                                <select id="program" name="program" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                    <option value="BSCS">BS Computer Science (BSCS)</option>
                                    <option value="BSIT">BS Information Technology (BSIT)</option>
                                    <option value="BSIS">BS Information Systems (BSIS)</option>
                                </select>
                            </div>
                            
                            <button type="submit" class="btn-action-primary" style="width: 100%;">REGISTER STUDENT</button>
                        </form>
                    </div>

                    <!-- Edit Student -->
                    <div class="form-card" id="editStudentSection" style="display: none; border-color: var(--neo-cyan);">
                        <div style="display:flex; justify-content:space-between; align-items:center; border-bottom: 1px solid var(--neo-border); margin-bottom: 1rem; padding-bottom:0.5rem;">
                            <h3 style="margin-bottom:0; border:none;">Modify Student</h3>
                            <button class="btn-action-danger" style="padding: 0.1rem 0.4rem; font-size:0.7rem;" onclick="cancelEdit()">CLOSE</button>
                        </div>
                        <form action="${pageContext.request.contextPath}/StudentServlet" method="POST" class="neo-form">
                            <input type="hidden" name="action" value="update">
                            <input type="hidden" id="editStudentId" name="studentId">
                            
                            <div class="neo-form-group">
                                <label for="editStudentNo">Student Number</label>
                                <input type="text" id="editStudentNo" name="studentNo" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editLastName">Last Name</label>
                                <input type="text" id="editLastName" name="lastName" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editFirstName">First Name</label>
                                <input type="text" id="editFirstName" name="firstName" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editEmail">Email</label>
                                <input type="text" id="editEmail" name="email" required autocomplete="off">
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editYearLevel">Year Level</label>
                                <select id="editYearLevel" name="yearLevel" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                    <option value="1">1st Year</option>
                                    <option value="2">2nd Year</option>
                                    <option value="3">3rd Year</option>
                                    <option value="4">4th Year</option>
                                </select>
                            </div>
                            
                            <div class="neo-form-group">
                                <label for="editProgram">Program</label>
                                <select id="editProgram" name="program" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                    <option value="BSCS">BS Computer Science (BSCS)</option>
                                    <option value="BSIT">BS Information Technology (BSIT)</option>
                                    <option value="BSIS">BS Information Systems (BSIS)</option>
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
        function filterStudents() {
            var input = document.getElementById("studentSearch");
            var filter = input.value.toLowerCase();
            var rows = document.getElementsByClassName("student-row");
            
            for (var i = 0; i < rows.length; i++) {
                var num = rows[i].getElementsByClassName("student-no-col")[0].textContent.toLowerCase();
                var name = rows[i].getElementsByClassName("student-name-col")[0].textContent.toLowerCase();
                var email = rows[i].getElementsByClassName("student-email-col")[0].textContent.toLowerCase();
                var prog = rows[i].getElementsByClassName("student-prog-col")[0].textContent.toLowerCase();
                
                if (num.indexOf(filter) > -1 || name.indexOf(filter) > -1 || email.indexOf(filter) > -1 || prog.indexOf(filter) > -1) {
                    rows[i].style.display = "";
                } else {
                    rows[i].style.display = "none";
                }
            }
        }

        function editStudent(id, number, last, first, email, year, program) {
            document.getElementById("editStudentId").value = id;
            document.getElementById("editStudentNo").value = number;
            document.getElementById("editLastName").value = last;
            document.getElementById("editFirstName").value = first;
            document.getElementById("editEmail").value = email;
            document.getElementById("editYearLevel").value = year;
            document.getElementById("editProgram").value = program;
            
            document.getElementById("addStudentSection").style.display = "none";
            document.getElementById("editStudentSection").style.display = "block";
            
            document.getElementById("editStudentSection").scrollIntoView({ behavior: 'smooth' });
        }

        function cancelEdit() {
            document.getElementById("editStudentSection").style.display = "none";
            document.getElementById("addStudentSection").style.display = "block";
        }
    </script>
</body>
</html>
