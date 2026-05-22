package servlets;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.MySQLStudentDAO;

@WebServlet("/StudentServlet")
public class StudentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private MySQLStudentDAO studentDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        studentDAO = new MySQLStudentDAO();
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
                String studentNo = request.getParameter("studentNo");
                String lastName = request.getParameter("lastName");
                String firstName = request.getParameter("firstName");
                String email = request.getParameter("email");
                String yearLevelStr = request.getParameter("yearLevel");
                String program = request.getParameter("program");
                
                if (studentNo != null && !studentNo.trim().isEmpty() &&
                    lastName != null && !lastName.trim().isEmpty() &&
                    firstName != null && !firstName.trim().isEmpty() &&
                    email != null && !email.trim().isEmpty() &&
                    yearLevelStr != null && program != null && !program.trim().isEmpty()) {
                    
                    int yearLevel = Integer.parseInt(yearLevelStr);
                    boolean success = studentDAO.addStudent(studentNo, lastName, firstName, email, yearLevel, program);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Student '" + studentNo.trim() + "' registered successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error registering student.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: All fields are required.");
                }
                
            } else if ("update".equalsIgnoreCase(action)) {
                String studentIdStr = request.getParameter("studentId");
                String studentNo = request.getParameter("studentNo");
                String lastName = request.getParameter("lastName");
                String firstName = request.getParameter("firstName");
                String email = request.getParameter("email");
                String yearLevelStr = request.getParameter("yearLevel");
                String program = request.getParameter("program");
                
                if (studentIdStr != null && studentNo != null && !studentNo.trim().isEmpty() &&
                    lastName != null && !lastName.trim().isEmpty() &&
                    firstName != null && !firstName.trim().isEmpty() &&
                    email != null && !email.trim().isEmpty() &&
                    yearLevelStr != null && program != null && !program.trim().isEmpty()) {
                    
                    int studentId = Integer.parseInt(studentIdStr);
                    int yearLevel = Integer.parseInt(yearLevelStr);
                    boolean success = studentDAO.updateStudent(studentId, studentNo, lastName, firstName, email, yearLevel, program);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Student '" + studentNo.trim() + "' updated successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error updating student.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: All fields are required.");
                }
                
            } else if ("delete".equalsIgnoreCase(action)) {
                String studentIdStr = request.getParameter("studentId");
                if (studentIdStr != null) {
                    int studentId = Integer.parseInt(studentIdStr);
                    boolean success = studentDAO.deleteStudent(studentId);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "Student record deleted successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error deleting student.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Student ID is required for deletion.");
                }
            }
        } catch (SQLException e) {
            session.setAttribute("crudMessage", "Database error: " + e.getMessage());
        } catch (NumberFormatException e) {
            session.setAttribute("crudMessage", "Invalid number input: " + e.getMessage());
        }

        response.sendRedirect("students.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("students.jsp");
    }
}
