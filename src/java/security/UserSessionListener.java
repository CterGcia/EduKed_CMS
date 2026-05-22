package security;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;
import config.DatabaseConfig;

public class UserSessionListener implements HttpSessionListener {

    @Override
    public void sessionCreated(HttpSessionEvent se) {
        // Session created
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        HttpSession session = se.getSession();
        Integer dbSessionId = (Integer) session.getAttribute("db_session_id");
        if (dbSessionId != null && DatabaseConfig.derbyUrl != null) {
            System.out.println("Session inactivity timeout. Logging out db session ID: " + dbSessionId);
            try (Connection conn = DriverManager.getConnection(DatabaseConfig.derbyUrl);
                 PreparedStatement pstmt = conn.prepareStatement(
                         "UPDATE Sessions SET logout_time = CURRENT_TIMESTAMP WHERE session_id = ? AND logout_time IS NULL")) {
                pstmt.setInt(1, dbSessionId);
                pstmt.executeUpdate();
            } catch (SQLException e) {
                System.err.println("Failed to log session timeout in Derby: " + e.getMessage());
            }
        }
    }
}
