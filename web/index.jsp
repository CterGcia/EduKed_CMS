<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Prevent caching of login page
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    
    // If user is already logged in, redirect to dashboard
    if (session != null && session.getAttribute("username") != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    
    String error = (String) request.getAttribute("errorMessage");
    if (error == null) {
        error = (String) session.getAttribute("errorMessage");
        if (error != null) {
            session.removeAttribute("errorMessage");
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduKed CMS - Login</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
    <!-- Style -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/neo-brutalist.css">
    <style>
        .login-box {
            border: 2px solid var(--neo-cyan) !important;
            box-shadow: 6px 6px 0px 0px var(--neo-cyan);
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-box">
            <div class="login-brand">// Active Learning, Inc.</div>
            <h1 class="login-title">EduKed CMS</h1>
            <p class="login-sub">Course Management System Login</p>
            
            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="error-banner">
                    <%= error %>
                </div>
            <% } %>
            
            <form action="${pageContext.request.contextPath}/LoginServlet" method="POST" class="neo-form">
                <div class="neo-form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" placeholder="Enter username" required autocomplete="off">
                </div>
                
                <div class="neo-form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" placeholder="Enter password" required>
                </div>
                
                <div class="neo-form-group">
                    <label for="captchaInput">CAPTCHA Verification</label>
                    <div class="captcha-row">
                        <img id="captchaImg" src="${pageContext.request.contextPath}/CaptchaServlet" alt="CAPTCHA Image">
                        <button type="button" class="captcha-refresh" onclick="refreshCaptcha()">REFRESH</button>
                    </div>
                    <input type="text" id="captchaInput" name="captchaInput" placeholder="Enter CAPTCHA code" required autocomplete="off" class="mt-1">
                </div>
                
                <div class="neo-form-group mt-2">
                    <button type="submit" class="btn-action-primary" style="width: 100%;">AUTHENTICATE</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function refreshCaptcha() {
            var img = document.getElementById("captchaImg");
            img.src = "${pageContext.request.contextPath}/CaptchaServlet?" + new Date().getTime();
        }
    </script>
</body>
</html>
