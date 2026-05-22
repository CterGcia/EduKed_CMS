package servlets;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.MySQLCourseDAO;

@WebServlet("/CourseServlet")
public class CourseServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private MySQLCourseDAO courseDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        courseDAO = new MySQLCourseDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("error_session.jsp");
            return;
        }

        String role = (String) session.getAttribute("role");
        if (!"admin".equalsIgnoreCase(role)) {
            response.sendRedirect("error_403.jsp");
            return;
        }

        String action = request.getParameter("action");
        try {
            if ("add".equalsIgnoreCase(action)) {
                String courseCode = request.getParameter("courseCode");
                String title = request.getParameter("title");
                String description = request.getParameter("description");
                String unitsStr = request.getParameter("units");
                String scheduleIdStr = request.getParameter("scheduleId");
                String instructorIdStr = request.getParameter("instructorId");
                
                if (courseCode != null && !courseCode.trim().isEmpty() && title != null && !title.trim().isEmpty() && unitsStr != null) {
                    int units = Integer.parseInt(unitsStr);
                    Integer scheduleId = (scheduleIdStr != null && !scheduleIdStr.trim().isEmpty()) ? Integer.parseInt(scheduleIdStr) : null;
                    Integer instructorId = (instructorIdStr != null && !instructorIdStr.trim().isEmpty()) ? Integer.parseInt(instructorIdStr) : null;
                    
                    boolean success = courseDAO.addCourse(courseCode.trim(), title.trim(), description, units, scheduleId, instructorId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Course '" + courseCode.trim() + "' added successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error adding course.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Course Code, Title, and Units are required.");
                }
                
            } else if ("update".equalsIgnoreCase(action)) {
                String courseIdStr = request.getParameter("courseId");
                String courseCode = request.getParameter("courseCode");
                String title = request.getParameter("title");
                String description = request.getParameter("description");
                String unitsStr = request.getParameter("units");
                String scheduleIdStr = request.getParameter("scheduleId");
                String instructorIdStr = request.getParameter("instructorId");
                
                if (courseIdStr != null && courseCode != null && !courseCode.trim().isEmpty() && title != null && !title.trim().isEmpty() && unitsStr != null) {
                    int courseId = Integer.parseInt(courseIdStr);
                    int units = Integer.parseInt(unitsStr);
                    Integer scheduleId = (scheduleIdStr != null && !scheduleIdStr.trim().isEmpty()) ? Integer.parseInt(scheduleIdStr) : null;
                    Integer instructorId = (instructorIdStr != null && !instructorIdStr.trim().isEmpty()) ? Integer.parseInt(instructorIdStr) : null;
                    
                    boolean success = courseDAO.updateCourse(courseId, courseCode.trim(), title.trim(), description, units, scheduleId, instructorId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Course '" + courseCode.trim() + "' updated successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error updating course.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Course ID, Course Code, Title, and Units are required.");
                }
                
            } else if ("delete".equalsIgnoreCase(action)) {
                String courseIdStr = request.getParameter("courseId");
                if (courseIdStr != null) {
                    int courseId = Integer.parseInt(courseIdStr);
                    boolean success = courseDAO.deleteCourse(courseId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Course deleted successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error deleting course.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Course ID is required for deletion.");
                }
            }
        } catch (SQLException e) {
            session.setAttribute("crudMessage", "Database error: " + e.getMessage());
        } catch (NumberFormatException e) {
            session.setAttribute("crudMessage", "Invalid number input: " + e.getMessage());
        }

        response.sendRedirect("courses.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("courses.jsp");
    }
}
