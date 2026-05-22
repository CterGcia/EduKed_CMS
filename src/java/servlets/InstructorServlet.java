package servlets;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.MySQLInstructorDAO;

@WebServlet("/InstructorServlet")
public class InstructorServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private MySQLInstructorDAO instructorDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        instructorDAO = new MySQLInstructorDAO();
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
                String lastName = request.getParameter("lastName");
                String firstName = request.getParameter("firstName");
                String department = request.getParameter("department");
                String userIdStr = request.getParameter("userId");
                
                if (lastName != null && !lastName.trim().isEmpty() &&
                    firstName != null && !firstName.trim().isEmpty() &&
                    department != null && !department.trim().isEmpty()) {
                    
                    Integer userId = (userIdStr != null && !userIdStr.trim().isEmpty()) ? Integer.parseInt(userIdStr) : null;
                    boolean success = instructorDAO.addInstructor(lastName, firstName, department, userId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Instructor '" + lastName + ", " + firstName + "' registered successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error registering instructor.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Last Name, First Name, and Department are required.");
                }
                
            } else if ("update".equalsIgnoreCase(action)) {
                String instructorIdStr = request.getParameter("instructorId");
                String lastName = request.getParameter("lastName");
                String firstName = request.getParameter("firstName");
                String department = request.getParameter("department");
                String userIdStr = request.getParameter("userId");
                
                if (instructorIdStr != null && lastName != null && !lastName.trim().isEmpty() &&
                    firstName != null && !firstName.trim().isEmpty() &&
                    department != null && !department.trim().isEmpty()) {
                    
                    int instructorId = Integer.parseInt(instructorIdStr);
                    Integer userId = (userIdStr != null && !userIdStr.trim().isEmpty()) ? Integer.parseInt(userIdStr) : null;
                    boolean success = instructorDAO.updateInstructor(instructorId, lastName, firstName, department, userId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Instructor record updated successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error updating instructor.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: All fields except User ID are required.");
                }
                
            } else if ("delete".equalsIgnoreCase(action)) {
                String instructorIdStr = request.getParameter("instructorId");
                if (instructorIdStr != null) {
                    int instructorId = Integer.parseInt(instructorIdStr);
                    boolean success = instructorDAO.deleteInstructor(instructorId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Instructor record deleted successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error deleting instructor.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Instructor ID is required for deletion.");
                }
            }
        } catch (SQLException e) {
            session.setAttribute("crudMessage", "Database error: " + e.getMessage());
        } catch (NumberFormatException e) {
            session.setAttribute("crudMessage", "Invalid number input: " + e.getMessage());
        }

        response.sendRedirect("instructors.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("instructors.jsp");
    }
}
