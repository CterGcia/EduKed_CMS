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
    <title>EduKed CMS - Access Forbidden</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
</head>
<body>
    <div class="error-page-container">
        <div class="error-code-display" style="color: var(--neo-crimson);">403</div>
        <h1 class="error-title">Access Restricted / Denied</h1>
        <p class="error-message">You do not possess the required authorization credentials (ADMIN) to inspect this database ledger. If you believe this is an error, please coordinate with system staff.</p>
        <div class="error-actions">
            <a href="dashboard.jsp" class="btn-action-primary">BACK TO DASHBOARD</a>
            <a href="index.jsp" class="btn-action-primary">RE-AUTHENTICATE</a>
        </div>
    </div>
</body>
</html>
