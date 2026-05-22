package servlets;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.DerbyUserDAO;
import dao.DerbySessionDAO;
import model.User;
import security.HashUtility;
import exceptions.AuthenticationException;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private DerbyUserDAO userDAO;
    private DerbySessionDAO sessionDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        userDAO = new DerbyUserDAO();
        sessionDAO = new DerbySessionDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String captchaInput = request.getParameter("captchaInput");
        
        HttpSession session = request.getSession(true);
        String sessionCaptcha = (String) session.getAttribute("captcha_key");
        
        // 1. Check for empty fields
        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Both username and password fields are empty.");
            RequestDispatcher rd = request.getRequestDispatcher("noLoginCredentials.jsp");
            rd.forward(request, response);
            return;
        }
        
        // 2. Validate CAPTCHA
        if (captchaInput == null || sessionCaptcha == null || !captchaInput.trim().equalsIgnoreCase(sessionCaptcha)) {
            request.setAttribute("errorMessage", "Invalid CAPTCHA code. Please try again.");
            RequestDispatcher rd = request.getRequestDispatcher("index.jsp");
            rd.forward(request, response);
            return;
        }
        
        // Clear CAPTCHA after use to prevent replay
        session.removeAttribute("captcha_key");
        
        try {
            // 3. Hash password and authenticate
            String passwordHash = HashUtility.hashPassword(password);
            User user = userDAO.authenticate(username, passwordHash);
            
            // 4. Authentication success: establish sessions
            session.setAttribute("username", user.getUsername());
            session.setAttribute("role", user.getRole());
            
            // Record session in Derby
            int dbSessionId = sessionDAO.createSession(user.getUserId());
            session.setAttribute("db_session_id", dbSessionId);
            
            // Redirect to dashboard
            response.sendRedirect("dashboard.jsp");
            
        } catch (AuthenticationException e) {
            request.setAttribute("errorMessage", e.getMessage());
            if (e.getMessage().contains("Username not found")) {
                // Username incorrect -> error_1.jsp
                RequestDispatcher rd = request.getRequestDispatcher("error_1.jsp");
                rd.forward(request, response);
            } else {
                // Password incorrect -> error_2.jsp
                RequestDispatcher rd = request.getRequestDispatcher("error_2.jsp");
                rd.forward(request, response);
            }
        } catch (SQLException e) {
            throw new ServletException("Database system error during login", e);
        }
    }
}
