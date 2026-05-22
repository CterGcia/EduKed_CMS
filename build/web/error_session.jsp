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
    <title>EduKed CMS - Session Timeout</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
</head>
<body>
    <div class="error-page-container">
        <div class="error-code-display" style="color: var(--neo-crimson);">TIMEOUT</div>
        <h1 class="error-title">Inactivity Session Timeout</h1>
        <p class="error-message">Your system login session has expired after exactly 5 minutes of inactivity. For database security, the timeout event was captured and registered.</p>
        <div class="error-actions">
            <a href="index.jsp" class="btn-action-primary">LOG BACK IN</a>
        </div>
    </div>
</body>
</html>
