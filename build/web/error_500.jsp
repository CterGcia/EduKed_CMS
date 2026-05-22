<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String errorCode = (String) request.getAttribute("errorCode");
    String errorMessage = (String) request.getAttribute("errorMessage");
    String requestUri = (String) request.getAttribute("requestUri");

    if (errorCode == null) errorCode = "500";
    if (errorMessage == null) errorMessage = "A critical database exception or internal system error has occurred.";
    if (requestUri == null) requestUri = "N/A";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - System Error</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .diagnostics-box {
            background: var(--neo-surface);
            border: 1px solid var(--neo-border);
            padding: 1.5rem;
            max-width: 600px;
            width: 100%;
            margin-top: 1rem;
            text-align: left;
        }
        .diagnostics-title {
            font-family: var(--neo-mono);
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--neo-muted);
            border-bottom: 1px solid var(--neo-border);
            padding-bottom: 0.4rem;
            margin-bottom: 0.8rem;
        }
        .diagnostics-field {
            font-family: var(--neo-mono);
            font-size: 0.8rem;
            margin-bottom: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="error-page-container" style="padding: 2rem;">
        <div class="error-code-display" style="color: var(--neo-crimson);"><%= errorCode %></div>
        <h1 class="error-title">Internal Server Exception</h1>
        <p class="error-message">A system runtime anomaly was detected. The incident has been logged in PostgreSQL `ErrorLogs` for administrative review.</p>
        
        <div class="diagnostics-box">
            <div class="diagnostics-title">Diagnostic Logs (Console)</div>
            <div class="diagnostics-field">
                <span class="text-muted">REQUEST URI:</span> <span class="text-cyan"><%= requestUri %></span>
            </div>
            <div class="diagnostics-field">
                <span class="text-muted">LOGGED CODE:</span> <span class="text-danger"><%= errorCode %></span>
            </div>
            <div class="diagnostics-field">
                <span class="text-muted">EXC MESSAGE:</span> <span style="word-break: break-all;"><%= errorMessage %></span>
            </div>
        </div>

        <div class="error-actions" style="margin-top: 1rem;">
            <a href="dashboard.jsp" class="btn-action-primary">CONSOLE HOME</a>
            <a href="index.jsp" class="btn-action-primary">RE-AUTHENTICATE</a>
        </div>
    </div>
</body>
</html>
