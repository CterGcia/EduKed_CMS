package servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import dao.PostgreSQLErrorDAO;

@WebServlet("/ErrorHandlerServlet")
public class ErrorHandlerServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private PostgreSQLErrorDAO errorDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        errorDAO = new PostgreSQLErrorDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processError(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processError(request, response);
    }

    private void processError(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        Throwable throwable = (Throwable) request.getAttribute("javax.servlet.error.exception");
        Integer statusCode = (Integer) request.getAttribute("javax.servlet.error.status_code");
        String requestUri = (String) request.getAttribute("javax.servlet.error.request_uri");
        
        String errorCode = String.valueOf(statusCode != null ? statusCode : "500");
        String message = "";
        String stackTrace = "";

        if (throwable != null) {
            message = throwable.getMessage();
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            throwable.printStackTrace(pw);
            stackTrace = sw.toString();
        } else {
            message = "Error at request URI: " + (requestUri != null ? requestUri : "Unknown URI");
        }

        // Persist to PostgreSQL ErrorLogs
        try {
            errorDAO.logError(errorCode, message, stackTrace);
        } catch (Exception e) {
            // Log fallback to server console if PostgreSQL is down or another error occurs
            System.err.println("PostgreSQL Error Logging failed: " + e.getMessage());
            e.printStackTrace();
        }

        // Set attributes for the JSP error screen
        request.setAttribute("errorCode", errorCode);
        request.setAttribute("errorMessage", message);
        request.setAttribute("requestUri", requestUri);

        // Forward to error_500.jsp
        request.getRequestDispatcher("/error_500.jsp").forward(request, response);
    }
}
