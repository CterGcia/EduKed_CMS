package servlets;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.DerbySessionDAO;

@WebServlet("/LogoutServlet")
public class LogoutServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private DerbySessionDAO sessionDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        sessionDAO = new DerbySessionDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processLogout(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processLogout(request, response);
    }

    private void processLogout(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Integer dbSessionId = (Integer) session.getAttribute("db_session_id");
            if (dbSessionId != null) {
                try {
                    sessionDAO.endSession(dbSessionId);
                } catch (SQLException e) {
                    System.err.println("Database error during logout: " + e.getMessage());
                }
            }
            session.invalidate();
        }
        response.sendRedirect("logout.jsp");
    }
}
