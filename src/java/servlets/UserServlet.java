package servlets;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.DerbyUserDAO;
import exceptions.AuthenticationException;
import security.HashUtility;

@WebServlet("/UserServlet")
public class UserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private DerbyUserDAO userDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        userDAO = new DerbyUserDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("error_session.jsp");
            return;
        }

        String loggedInUser = (String) session.getAttribute("username");
        String loggedInRole = (String) session.getAttribute("role");
        String action = request.getParameter("action");
        
        try {
            if ("changePassword".equalsIgnoreCase(action)) {
                // Anyone can change their own password
                String oldPassword = request.getParameter("oldPassword");
                String newPassword = request.getParameter("newPassword");
                
                if (oldPassword == null || oldPassword.trim().isEmpty() || newPassword == null || newPassword.trim().isEmpty()) {
                    session.setAttribute("crudMessage", "Error: All password fields are required.");
                } else {
                    String oldPasswordHash = HashUtility.hashPassword(oldPassword);
                    String newPasswordHash = HashUtility.hashPassword(newPassword);
                    
                    try {
                        boolean success = userDAO.changePassword(loggedInUser, oldPasswordHash, newPasswordHash);
                        if (success) {
                            session.setAttribute("crudSuccessMessage", "Password updated successfully.");
                        } else {
                            session.setAttribute("crudMessage", "Error updating password.");
                        }
                    } catch (AuthenticationException ae) {
                        session.setAttribute("crudMessage", "Error: Incorrect current password.");
                    }
                }
                response.sendRedirect("users.jsp");
                return;
            }
            
            // Other actions are Admin-only
            if (!"admin".equalsIgnoreCase(loggedInRole)) {
                response.sendRedirect("error_403.jsp");
                return;
            }
            
            if ("add".equalsIgnoreCase(action)) {
                String newUsername = request.getParameter("newUsername");
                String newPassword = request.getParameter("newPassword");
                String newRole = request.getParameter("newRole");
                
                if (newUsername != null && !newUsername.trim().isEmpty() &&
                    newPassword != null && !newPassword.trim().isEmpty() &&
                    newRole != null && !newRole.trim().isEmpty()) {
                    
                    String newPasswordHash = HashUtility.hashPassword(newPassword);
                    boolean success = userDAO.addUser(newUsername, newPasswordHash, newRole);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "User '" + newUsername.trim() + "' added successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error adding user.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: All fields are required to add a user.");
                }
                
            } else if ("update".equalsIgnoreCase(action)) {
                String editUsername = request.getParameter("editUsername");
                String editPassword = request.getParameter("editPassword");
                String editRole = request.getParameter("editRole");
                
                if (editUsername != null && !editUsername.trim().isEmpty() && editRole != null && !editRole.trim().isEmpty()) {
                    String editPasswordHash = null;
                    if (editPassword != null && !editPassword.trim().isEmpty()) {
                        editPasswordHash = HashUtility.hashPassword(editPassword);
                    }
                    
                    boolean success = userDAO.updateUser(editUsername, editPasswordHash, editRole);
                    if (success) {
                        session.setAttribute("crudSuccessMessage", "User '" + editUsername.trim() + "' updated successfully.");
                    } else {
                        session.setAttribute("crudMessage", "Error updating user.");
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Username and Role are required to update a user.");
                }
                
            } else if ("delete".equalsIgnoreCase(action)) {
                String deleteUsername = request.getParameter("deleteUsername");
                
                if (deleteUsername != null && !deleteUsername.trim().isEmpty()) {
                    if (deleteUsername.trim().equals(loggedInUser)) {
                        session.setAttribute("crudMessage", "Error: You cannot delete your own account while logged in.");
                    } else {
                        boolean success = userDAO.deleteUser(deleteUsername);
                        if (success) {
                            session.setAttribute("crudSuccessMessage", "User '" + deleteUsername.trim() + "' deleted successfully.");
                        } else {
                            session.setAttribute("crudMessage", "Error deleting user.");
                        }
                    }
                } else {
                    session.setAttribute("crudMessage", "Error: Username is required for deletion.");
                }
            }
            
        } catch (SQLException e) {
            session.setAttribute("crudMessage", "Database error: " + e.getMessage());
        }
        
        response.sendRedirect("users.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("users.jsp");
    }
}
