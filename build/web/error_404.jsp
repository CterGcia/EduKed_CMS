<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - File Not Found</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
</head>
<body>
    <div class="error-page-container">
        <div class="error-code-display" style="color: var(--neo-cyan);">404</div>
        <h1 class="error-title">Page Not Found</h1>
        <p class="error-message">The requested resource could not be located on the server. Please verify the URL or link parameters.</p>
        <div class="error-actions">
            <a href="dashboard.jsp" class="btn-action-primary">RETURN TO DASHBOARD</a>
        </div>
    </div>
</body>
</html>
