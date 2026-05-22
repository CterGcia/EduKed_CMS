package servlets;

import java.io.IOException;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.FontFactory;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

import config.DatabaseConfig;
import dao.DerbyUserDAO;
import dao.DerbySessionDAO;
import dao.MySQLCourseDAO;
import dao.PostgreSQLAuditDAO;
import dao.PostgreSQLErrorDAO;
import model.User;
import model.UserSession;
import model.Course;
import model.ReportLog;
import model.ErrorLog;
import reports.ReportPageHelper;

@WebServlet("/ReportServlet")
public class ReportServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private DerbyUserDAO userDAO;
    private DerbySessionDAO sessionDAO;
    private MySQLCourseDAO courseDAO;
    private PostgreSQLAuditDAO auditDAO;
    private PostgreSQLErrorDAO errorDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        userDAO = new DerbyUserDAO();
        sessionDAO = new DerbySessionDAO();
        courseDAO = new MySQLCourseDAO();
        auditDAO = new PostgreSQLAuditDAO();
        errorDAO = new PostgreSQLErrorDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    private void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("error_session.jsp");
            return;
        }

        String loggedInUser = (String) session.getAttribute("username");
        String loggedInRole = (String) session.getAttribute("role");
        String reportType = request.getParameter("reportType");

        if (reportType == null) {
            response.sendRedirect("reports.jsp");
            return;
        }

        // Access Control checks
        if (!"COURSE_CATALOG".equalsIgnoreCase(reportType) && !"admin".equalsIgnoreCase(loggedInRole)) {
            response.sendRedirect("error_403.jsp");
            return;
        }

        // Validate time-bound inputs beforehand if applicable
        Timestamp startTs = null;
        Timestamp endTs = null;
        String logSource = null;
        if ("TIME_BOUND".equalsIgnoreCase(reportType) || "TIME_BOUND_USERS".equalsIgnoreCase(reportType)) {
            String startDateStr = request.getParameter("startDate");
            String endDateStr = request.getParameter("endDate");
            if ("TIME_BOUND".equalsIgnoreCase(reportType)) {
                logSource = request.getParameter("logSource"); // "ReportLogs" or "ErrorLogs"
            }
            
            if (startDateStr == null || startDateStr.trim().isEmpty() || endDateStr == null || endDateStr.trim().isEmpty()) {
                session.setAttribute("crudMessage", "Error: Both Start Date and End Date are required.");
                response.sendRedirect("reports.jsp");
                return;
            }

            try {
                // Support both HTML5 datetime-local ("yyyy-MM-dd'T'HH:mm") and date ("yyyy-MM-dd") formats
                SimpleDateFormat parser;
                if (startDateStr.contains("T")) {
                    parser = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm");
                } else {
                    parser = new SimpleDateFormat("yyyy-MM-dd");
                }
                
                Date startDate = parser.parse(startDateStr);
                Date endDate = parser.parse(endDateStr);
                
                if (startDate.after(endDate)) {
                    session.setAttribute("crudMessage", "Error: Start Date cannot be after End Date.");
                    response.sendRedirect("reports.jsp");
                    return;
                }
                
                startTs = new Timestamp(startDate.getTime());
                endTs = new Timestamp(endDate.getTime());
                
            } catch (ParseException e) {
                session.setAttribute("crudMessage", "Error: Invalid date format.");
                response.sendRedirect("reports.jsp");
                return;
            }
        }

        // Generate Filename
        String timestampStr = new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
        String filename = "";
        String titleText = "";
        
        if ("ALL_RECORDS".equalsIgnoreCase(reportType)) {
            filename = "ALLUSERS_" + timestampStr + ".pdf";
            titleText = "EduKed CMS - All User Accounts Report";
        } else if ("OWN_RECORDS".equalsIgnoreCase(reportType)) {
            filename = "OWNRECORDS_" + timestampStr + ".pdf";
            titleText = "EduKed CMS - Admin Session History Report (" + loggedInUser + ")";
        } else if ("TIME_BOUND".equalsIgnoreCase(reportType)) {
            filename = "AUDITLOGS_" + timestampStr + ".pdf";
            titleText = "EduKed CMS - Time-Bound System Audit Report (" + logSource + ")";
        } else if ("TIME_BOUND_USERS".equalsIgnoreCase(reportType)) {
            filename = "USERS_CREATED_" + timestampStr + ".pdf";
            titleText = "EduKed CMS - Time-Bound Users Created Report";
        } else if ("COURSE_CATALOG".equalsIgnoreCase(reportType)) {
            filename = "COURSECATALOG_" + timestampStr + ".pdf";
            titleText = "EduKed CMS - Academic Course Catalog Report";
        }

        // Configure iText Response
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=" + filename);

        // Fetch running headers/footers from configuration
        String headerText = DatabaseConfig.pdfHeaderText != null ? DatabaseConfig.pdfHeaderText : "ACTIVE LEARNING, INC. - SYSTEM REPORT";
        String footerText = DatabaseConfig.pdfFooterText != null ? DatabaseConfig.pdfFooterText : "Confidential. System Generated.";

        // Create PDF Document (Landscape mode size letter)
        Document document = new Document(PageSize.LETTER.rotate(), 36, 36, 54, 54);
        try {
            PdfWriter writer = PdfWriter.getInstance(document, response.getOutputStream());
            writer.setPageEvent(new ReportPageHelper(headerText, footerText, loggedInUser));
            document.open();

            // Document Header Styling
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, new BaseColor(18, 24, 36));
            Font metaFont = FontFactory.getFont(FontFactory.HELVETICA, 10, BaseColor.DARK_GRAY);
            
            Paragraph titlePara = new Paragraph(titleText, titleFont);
            titlePara.setAlignment(Element.ALIGN_CENTER);
            titlePara.setSpacingAfter(5f);
            document.add(titlePara);

            Paragraph metaPara = new Paragraph("Generated on: " + new SimpleDateFormat("yyyy-MM-dd hh:mm a").format(new Date()) + " | Generated by: " + loggedInUser, metaFont);
            metaPara.setAlignment(Element.ALIGN_CENTER);
            metaPara.setSpacingAfter(20f);
            document.add(metaPara);

            // Populate Report Body
            if ("ALL_RECORDS".equalsIgnoreCase(reportType)) {
                buildAllUsersTable(document, loggedInUser);
            } else if ("OWN_RECORDS".equalsIgnoreCase(reportType)) {
                buildOwnRecordsTable(document, loggedInUser);
            } else if ("TIME_BOUND".equalsIgnoreCase(reportType)) {
                buildTimeBoundTable(document, startTs, endTs, logSource);
            } else if ("TIME_BOUND_USERS".equalsIgnoreCase(reportType)) {
                buildUsersCreatedWithinRangeTable(document, startTs, endTs, loggedInUser);
            } else if ("COURSE_CATALOG".equalsIgnoreCase(reportType)) {
                buildCourseCatalogTable(document);
            }

            // Close document
            document.close();
            
            // Log PDF generation to PostgreSQL audit logs
            auditDAO.logReport(loggedInUser, reportType.toUpperCase(), filename);

        } catch (DocumentException e) {
            throw new ServletException("Error while writing PDF file structure", e);
        } catch (SQLException e) {
            throw new ServletException("Database access issue during report generation", e);
        }
    }

    private void buildAllUsersTable(Document doc, String activeAdmin) throws DocumentException, SQLException {
        List<User> list = userDAO.getAllUsers();
        
        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setSpacingBefore(10f);
        table.setWidths(new float[] {1f, 3f, 2f, 3f});

        addTableHeaderCell(table, "User ID");
        addTableHeaderCell(table, "Username");
        addTableHeaderCell(table, "Role");
        addTableHeaderCell(table, "Created At");

        Font fontBody = FontFactory.getFont(FontFactory.HELVETICA, 10);

        for (User u : list) {
            String displayUsername = u.getUsername();
            if (displayUsername.equals(activeAdmin)) {
                displayUsername += "*"; // Append asterisk to current active user
            }
            
            table.addCell(new PdfPCell(new Phrase(String.valueOf(u.getUserId()), fontBody)));
            table.addCell(new PdfPCell(new Phrase(displayUsername, fontBody)));
            table.addCell(new PdfPCell(new Phrase(u.getRole(), fontBody)));
            table.addCell(new PdfPCell(new Phrase(u.getCreatedAt() != null ? u.getCreatedAt().toString() : "N/A", fontBody)));
        }

        doc.add(table);
    }

    private void buildOwnRecordsTable(Document doc, String activeAdmin) throws DocumentException, SQLException {
        // Retrieve Admin User ID first
        List<User> users = userDAO.getAllUsers();
        int userId = -1;
        for (User u : users) {
            if (u.getUsername().equals(activeAdmin)) {
                userId = u.getUserId();
                break;
            }
        }

        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setSpacingBefore(10f);
        table.setWidths(new float[] {2f, 3f, 3f, 2f});

        addTableHeaderCell(table, "Session ID");
        addTableHeaderCell(table, "Login Time");
        addTableHeaderCell(table, "Logout Time");
        addTableHeaderCell(table, "Status");

        Font fontBody = FontFactory.getFont(FontFactory.HELVETICA, 10);

        if (userId != -1) {
            List<UserSession> sessions = sessionDAO.getSessionHistory(userId);
            for (UserSession s : sessions) {
                String loginTimeStr = s.getLoginTime() != null ? s.getLoginTime().toString() : "N/A";
                String logoutTimeStr = s.getLogoutTime() != null ? s.getLogoutTime().toString() : "N/A";
                String status = s.getLogoutTime() == null ? "Active" : "Logged Out";

                table.addCell(new PdfPCell(new Phrase(String.valueOf(s.getSessionId()), fontBody)));
                table.addCell(new PdfPCell(new Phrase(loginTimeStr, fontBody)));
                table.addCell(new PdfPCell(new Phrase(logoutTimeStr, fontBody)));
                
                PdfPCell statusCell = new PdfPCell(new Phrase(status, fontBody));
                if ("Active".equals(status)) {
                    statusCell.setBackgroundColor(new BaseColor(230, 255, 230)); // Subtle light green background
                }
                table.addCell(statusCell);
            }
        }
        doc.add(table);
    }

    private void buildTimeBoundTable(Document doc, Timestamp start, Timestamp end, String source) throws DocumentException, SQLException {
        Font fontBody = FontFactory.getFont(FontFactory.HELVETICA, 10);
        
        if ("ReportLogs".equalsIgnoreCase(source)) {
            List<ReportLog> list = auditDAO.getReportLogsFiltered(start, end);
            
            PdfPTable table = new PdfPTable(5);
            table.setWidthPercentage(100);
            table.setSpacingBefore(10f);
            table.setWidths(new float[] {1f, 2f, 2f, 3f, 2f});

            addTableHeaderCell(table, "Log ID");
            addTableHeaderCell(table, "Generated By");
            addTableHeaderCell(table, "Report Type");
            addTableHeaderCell(table, "Filename");
            addTableHeaderCell(table, "Timestamp");

            if (list.isEmpty()) {
                PdfPCell emptyCell = new PdfPCell(new Phrase("No records found in this date range.", fontBody));
                emptyCell.setColspan(5);
                emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                emptyCell.setPadding(10f);
                table.addCell(emptyCell);
            } else {
                for (ReportLog l : list) {
                    table.addCell(new PdfPCell(new Phrase(String.valueOf(l.getReportId()), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getGeneratedBy(), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getReportType(), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getFilename(), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getGeneratedAt().toString(), fontBody)));
                }
            }
            doc.add(table);
            
        } else {
            List<ErrorLog> list = errorDAO.getErrorLogsFiltered(start, end);
            
            PdfPTable table = new PdfPTable(5);
            table.setWidthPercentage(100);
            table.setSpacingBefore(10f);
            table.setWidths(new float[] {1f, 2f, 3f, 4f, 2f});

            addTableHeaderCell(table, "Error ID");
            addTableHeaderCell(table, "Error Code");
            addTableHeaderCell(table, "Message");
            addTableHeaderCell(table, "Stack Excerpt");
            addTableHeaderCell(table, "Timestamp");

            if (list.isEmpty()) {
                PdfPCell emptyCell = new PdfPCell(new Phrase("No records found in this date range.", fontBody));
                emptyCell.setColspan(5);
                emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                emptyCell.setPadding(10f);
                table.addCell(emptyCell);
            } else {
                for (ErrorLog l : list) {
                    String stackExcerpt = l.getStack();
                    if (stackExcerpt != null && stackExcerpt.length() > 100) {
                        stackExcerpt = stackExcerpt.substring(0, 97) + "...";
                    }
                    table.addCell(new PdfPCell(new Phrase(String.valueOf(l.getErrorId()), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getErrorCode(), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getMessage(), fontBody)));
                    table.addCell(new PdfPCell(new Phrase(stackExcerpt != null ? stackExcerpt : "", fontBody)));
                    table.addCell(new PdfPCell(new Phrase(l.getTimestamp().toString(), fontBody)));
                }
            }
            doc.add(table);
        }
    }

    private void buildUsersCreatedWithinRangeTable(Document doc, Timestamp start, Timestamp end, String activeAdmin) throws DocumentException, SQLException {
        List<User> list = userDAO.getUsersCreatedBetween(start, end);

        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setSpacingBefore(10f);
        table.setWidths(new float[] {1f, 3f, 2f, 3f});

        addTableHeaderCell(table, "User ID");
        addTableHeaderCell(table, "Username");
        addTableHeaderCell(table, "Role");
        addTableHeaderCell(table, "Created At");

        Font fontBody = FontFactory.getFont(FontFactory.HELVETICA, 10);

        if (list.isEmpty()) {
            PdfPCell emptyCell = new PdfPCell(new Phrase("No user accounts were created in this date range.", fontBody));
            emptyCell.setColspan(4);
            emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
            emptyCell.setPadding(10f);
            table.addCell(emptyCell);
        } else {
            for (User u : list) {
                String displayUsername = u.getUsername();
                if (displayUsername.equals(activeAdmin)) {
                    displayUsername += "*";
                }

                table.addCell(new PdfPCell(new Phrase(String.valueOf(u.getUserId()), fontBody)));
                table.addCell(new PdfPCell(new Phrase(displayUsername, fontBody)));
                table.addCell(new PdfPCell(new Phrase(u.getRole(), fontBody)));
                table.addCell(new PdfPCell(new Phrase(u.getCreatedAt() != null ? u.getCreatedAt().toString() : "N/A", fontBody)));
            }
        }

        doc.add(table);
    }

    private void buildCourseCatalogTable(Document doc) throws DocumentException, SQLException {
        List<Course> list = courseDAO.getAllCourses();
        
        PdfPTable table = new PdfPTable(6);
        table.setWidthPercentage(100);
        table.setSpacingBefore(10f);
        table.setWidths(new float[] {2f, 4f, 1f, 3f, 2f, 3f});

        addTableHeaderCell(table, "Code");
        addTableHeaderCell(table, "Title");
        addTableHeaderCell(table, "Units");
        addTableHeaderCell(table, "Schedule");
        addTableHeaderCell(table, "Room");
        addTableHeaderCell(table, "Instructor");

        Font fontBody = FontFactory.getFont(FontFactory.HELVETICA, 10);

        for (Course c : list) {
            table.addCell(new PdfPCell(new Phrase(c.getCourseCode(), fontBody)));
            table.addCell(new PdfPCell(new Phrase(c.getTitle(), fontBody)));
            table.addCell(new PdfPCell(new Phrase(String.valueOf(c.getUnits()), fontBody)));
            table.addCell(new PdfPCell(new Phrase(c.getFormattedSchedule() != null ? c.getFormattedSchedule() : "N/A", fontBody)));
            table.addCell(new PdfPCell(new Phrase(c.getRoom() != null ? c.getRoom() : "N/A", fontBody)));
            table.addCell(new PdfPCell(new Phrase(c.getInstructorName() != null ? c.getInstructorName() : "Unassigned", fontBody)));
        }

        doc.add(table);
    }

    private void addTableHeaderCell(PdfPTable table, String text) {
        Font fontHeader = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, BaseColor.WHITE);
        PdfPCell cell = new PdfPCell(new Phrase(text, fontHeader));
        cell.setBackgroundColor(new BaseColor(38, 49, 71)); // Muted dark slate
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setPadding(6f);
        table.addCell(cell);
    }
}
