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
    <title>EduKed CMS - Incorrect Credentials</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .error-box {
            background: var(--neo-surface);
            border: 2px solid var(--neo-crimson) !important;
            box-shadow: 6px 6px 0px 0px var(--neo-crimson);
            padding: 2.5rem;
            max-width: 420px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="error-box">
            <div class="login-brand" style="color: var(--neo-crimson);">// Authentication Error</div>
            <h1 style="font-size: 1.4rem; margin-bottom: 0.5rem; color: var(--neo-text);">Incorrect Password</h1>
            <p style="margin-bottom: 1.5rem; font-size: 0.9rem;">The password signature does not align with the SHA-256 hash stored in the authentication directory. Please try again.</p>
            <a href="index.jsp" class="btn-action-primary" style="width: 100%;">RETURN TO LOGIN</a>
        </div>
    </div>
</body>
</html>
