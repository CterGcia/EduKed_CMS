<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="dao.MySQLCourseDAO" %>
<%@ page import="dao.MySQLInstructorDAO" %>
<%@ page import="model.Course" %>
<%@ page import="model.Schedule" %>
<%@ page import="model.Instructor" %>
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

    MySQLCourseDAO courseDAO = new MySQLCourseDAO();
    MySQLInstructorDAO instructorDAO = new MySQLInstructorDAO();
    
    List<Course> courseList = null;
    List<Schedule> scheduleList = null;
    List<Instructor> instructorList = null;
    
    try {
        courseList = courseDAO.getAllCourses();
        if ("admin".equalsIgnoreCase(role)) {
            scheduleList = courseDAO.getAllSchedules();
            instructorList = instructorDAO.getAllInstructors();
        }
    } catch (Exception e) {
        throw new ServletException("Database error loading Course Catalog metadata", e);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - Course Catalog</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .courses-layout {
            display: grid;
            grid-template-columns: <%= "admin".equalsIgnoreCase(role) ? "2fr 1fr" : "1fr" %>;
            gap: 1.5rem;
        }
        @media (max-width: 900px) {
            .courses-layout {
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
            display: flex;
            gap: 0.8rem;
        }
        .search-input {
            flex: 1;
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
            <a href="courses.jsp" class="active">Courses</a>
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
            <a href="dashboard.jsp">Console</a>
            <a href="courses.jsp" class="active">Course Catalog</a>
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
                <h1>Academic Course Catalog</h1>
                <p>Browse active course sections, view scheduling assignments, and manage catalogs.</p>
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

            <!-- Search and Actions Bar -->
            <div class="search-container">
                <input type="text" id="courseSearch" class="search-input" placeholder="Search courses by code, title, or instructor..." onkeyup="filterCourses()">
                <% if ("guest".equalsIgnoreCase(role)) { %>
                    <!-- Guests can print Course Catalog directly -->
                    <a href="${pageContext.request.contextPath}/ReportServlet?reportType=COURSE_CATALOG" class="btn-action-primary" style="display:flex; align-items:center;">PRINT CATALOG (PDF)</a>
                <% } %>
            </div>

            <div class="courses-layout">
                <!-- Left Side: Courses Table -->
                <div>
                    <div class="neo-section">
                        <table class="admin-data-grid" id="coursesTable">
                            <thead>
                                <tr>
                                    <th>Code</th>
                                    <th>Title</th>
                                    <th>Units</th>
                                    <th>Schedule</th>
                                    <th>Room</th>
                                    <th>Instructor</th>
                                    <% if ("admin".equalsIgnoreCase(role)) { %>
                                        <th style="width: 150px; text-align: center;">Actions</th>
                                    <% } %>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (courseList == null || courseList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="<%= "admin".equalsIgnoreCase(role) ? "7" : "6" %>" class="no-data">No courses are registered in the catalog.</td>
                                    </tr>
                                <% } else {
                                    for (Course c : courseList) { %>
                                        <tr class="course-row">
                                            <td class="course-code-col"><%= c.getCourseCode() %></td>
                                            <td class="course-title-col"><%= c.getTitle() %></td>
                                            <td><%= c.getUnits() %></td>
                                            <td><%= c.getFormattedSchedule() != null ? c.getFormattedSchedule() : "N/A" %></td>
                                            <td><%= c.getRoom() != null ? c.getRoom() : "N/A" %></td>
                                            <td class="course-instructor-col"><%= c.getInstructorName() != null ? c.getInstructorName() : "Unassigned" %></td>
                                            <% if ("admin".equalsIgnoreCase(role)) { %>
                                                <td style="text-align: center;">
                                                    <div style="display: flex; gap: 0.3rem; justify-content: center;">
                                                        <!-- Find schedules/instructors ids to populate edit form -->
                                                        <button class="btn-action-primary" style="padding: 0.2rem 0.5rem;" 
                                                                onclick="editCourse('<%= c.getCourseId() %>', '<%= c.getCourseCode() %>', '<%= c.getTitle().replace("'", "\\'") %>', '<%= c.getDescription() != null ? c.getDescription().replace("'", "\\'") : "" %>', '<%= c.getUnits() %>', '', '')">EDIT</button>
                                                        <form action="${pageContext.request.contextPath}/CourseServlet" method="POST" onsubmit="return confirm('Are you sure you want to delete this course? Deletion cascades/archives linked registrations.');" style="margin:0;">
                                                            <input type="hidden" name="action" value="delete">
                                                            <input type="hidden" name="courseId" value="<%= c.getCourseId() %>">
                                                            <button type="submit" class="btn-action-danger" style="padding: 0.2rem 0.5rem;">DELETE</button>
                                                        </form>
                                                    </div>
                                                </td>
                                            <% } %>
                                        </tr>
                                    <% }
                                } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Right Side: Forms (Admin Only) -->
                <% if ("admin".equalsIgnoreCase(role)) { %>
                    <div>
                        <!-- Add Course -->
                        <div class="form-card" id="addCourseSection">
                            <h3>Add New Course</h3>
                            <form action="${pageContext.request.contextPath}/CourseServlet" method="POST" class="neo-form">
                                <input type="hidden" name="action" value="add">
                                
                                <div class="neo-form-group">
                                    <label for="courseCode">Course Code</label>
                                    <input type="text" id="courseCode" name="courseCode" placeholder="e.g. ICS2609" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="title">Title</label>
                                    <input type="text" id="title" name="title" placeholder="e.g. Applications Development" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="description">Description</label>
                                    <input type="text" id="description" name="description" placeholder="Course overview / outline" autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="units">Units</label>
                                    <input type="text" id="units" name="units" placeholder="e.g. 3" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="scheduleId">Schedule & Room</label>
                                    <select id="scheduleId" name="scheduleId" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="">-- Select Schedule (Optional) --</option>
                                        <% if (scheduleList != null) {
                                            for (Schedule s : scheduleList) { 
                                                String day = "";
                                                switch(s.getDayOfWeek()) {
                                                    case 1: day = "Mon"; break;
                                                    case 2: day = "Tue"; break;
                                                    case 3: day = "Wed"; break;
                                                    case 4: day = "Thu"; break;
                                                    case 5: day = "Fri"; break;
                                                    case 6: day = "Sat"; break;
                                                    case 7: day = "Sun"; break;
                                                }
                                                String start = s.getStartTime() != null ? s.getStartTime().toString().substring(0,5) : "";
                                                String end = s.getEndTime() != null ? s.getEndTime().toString().substring(0,5) : "";
                                                %>
                                                <option value="<%= s.getScheduleId() %>"><%= day %> <%= start %>-<%= end %> (<%= s.getRoom() %>)</option>
                                            <% }
                                        } %>
                                    </select>
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="instructorId">Faculty Assignment</label>
                                    <select id="instructorId" name="instructorId" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="">-- Select Instructor (Optional) --</option>
                                        <% if (instructorList != null) {
                                            for (Instructor i : instructorList) { %>
                                                <option value="<%= i.getInstructorId() %>"><%= i.getLastName() %>, <%= i.getFirstName() %> (<%= i.getDepartment() %>)</option>
                                            <% }
                                        } %>
                                    </select>
                                </div>
                                
                                <button type="submit" class="btn-action-primary" style="width: 100%;">REGISTER COURSE</button>
                            </form>
                        </div>

                        <!-- Edit Course -->
                        <div class="form-card" id="editCourseSection" style="display: none; border-color: var(--neo-cyan);">
                            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom: 1px solid var(--neo-border); margin-bottom: 1rem; padding-bottom:0.5rem;">
                                <h3 style="margin-bottom:0; border:none;">Modify Course</h3>
                                <button class="btn-action-danger" style="padding: 0.1rem 0.4rem; font-size:0.7rem;" onclick="cancelEdit()">CLOSE</button>
                            </div>
                            <form action="${pageContext.request.contextPath}/CourseServlet" method="POST" class="neo-form">
                                <input type="hidden" name="action" value="update">
                                <input type="hidden" id="editCourseId" name="courseId">
                                
                                <div class="neo-form-group">
                                    <label for="editCourseCode">Course Code</label>
                                    <input type="text" id="editCourseCode" name="courseCode" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editTitle">Title</label>
                                    <input type="text" id="editTitle" name="title" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editDescription">Description</label>
                                    <input type="text" id="editDescription" name="description" autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editUnits">Units</label>
                                    <input type="text" id="editUnits" name="units" required autocomplete="off">
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editScheduleId">Schedule & Room</label>
                                    <select id="editScheduleId" name="scheduleId" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="">-- Select Schedule (Optional) --</option>
                                        <% if (scheduleList != null) {
                                            for (Schedule s : scheduleList) { 
                                                String day = "";
                                                switch(s.getDayOfWeek()) {
                                                    case 1: day = "Mon"; break;
                                                    case 2: day = "Tue"; break;
                                                    case 3: day = "Wed"; break;
                                                    case 4: day = "Thu"; break;
                                                    case 5: day = "Fri"; break;
                                                    case 6: day = "Sat"; break;
                                                    case 7: day = "Sun"; break;
                                                }
                                                String start = s.getStartTime() != null ? s.getStartTime().toString().substring(0,5) : "";
                                                String end = s.getEndTime() != null ? s.getEndTime().toString().substring(0,5) : "";
                                                %>
                                                <option value="<%= s.getScheduleId() %>"><%= day %> <%= start %>-<%= end %> (<%= s.getRoom() %>)</option>
                                            <% }
                                        } %>
                                    </select>
                                </div>
                                
                                <div class="neo-form-group">
                                    <label for="editInstructorId">Faculty Assignment</label>
                                    <select id="editInstructorId" name="instructorId" style="width:100%; background: var(--neo-surface); border:1px solid var(--neo-border); color: var(--neo-text); padding:0.6rem; font-family: var(--neo-mono);">
                                        <option value="">-- Select Instructor (Optional) --</option>
                                        <% if (instructorList != null) {
                                            for (Instructor i : instructorList) { %>
                                                <option value="<%= i.getInstructorId() %>"><%= i.getLastName() %>, <%= i.getFirstName() %> (<%= i.getDepartment() %>)</option>
                                            <% }
                                        } %>
                                    </select>
                                </div>
                                
                                <button type="submit" class="btn-action-primary" style="width: 100%;">UPDATE COURSE</button>
                            </form>
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

    <script>
        function filterCourses() {
            var input = document.getElementById("courseSearch");
            var filter = input.value.toLowerCase();
            var rows = document.getElementsByClassName("course-row");
            
            for (var i = 0; i < rows.length; i++) {
                var code = rows[i].getElementsByClassName("course-code-col")[0].textContent.toLowerCase();
                var title = rows[i].getElementsByClassName("course-title-col")[0].textContent.toLowerCase();
                var instructor = rows[i].getElementsByClassName("course-instructor-col")[0].textContent.toLowerCase();
                
                if (code.indexOf(filter) > -1 || title.indexOf(filter) > -1 || instructor.indexOf(filter) > -1) {
                    rows[i].style.display = "";
                } else {
                    rows[i].style.display = "none";
                }
            }
        }

        <% if ("admin".equalsIgnoreCase(role)) { %>
            function editCourse(id, code, title, desc, units, schedId, instId) {
                document.getElementById("editCourseId").value = id;
                document.getElementById("editCourseCode").value = code;
                document.getElementById("editTitle").value = title;
                document.getElementById("editDescription").value = desc;
                document.getElementById("editUnits").value = units;
                document.getElementById("editScheduleId").value = schedId;
                document.getElementById("editInstructorId").value = instId;
                
                document.getElementById("addCourseSection").style.display = "none";
                document.getElementById("editCourseSection").style.display = "block";
                
                document.getElementById("editCourseSection").scrollIntoView({ behavior: 'smooth' });
            }

            function cancelEdit() {
                document.getElementById("editCourseSection").style.display = "none";
                document.getElementById("addCourseSection").style.display = "block";
            }
        <% } %>
    </script>
</body>
</html>
