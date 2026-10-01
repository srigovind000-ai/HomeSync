<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%--
  login.jsp
  Front-end only for now. Wire this up later to a LoginServlet that:
    - reads request.getParameter("email") and request.getParameter("password")
    - checks them against the `users` table via JDBC
    - on success: creates an HttpSession and redirects to dashboard.jsp
    - on failure: forwards back here with an error message, e.g.
      request.setAttribute("errorMessage", "Invalid email or password");
      request.getRequestDispatcher("login.jsp").forward(request, response);
--%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Log In · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
</head>
<body>

<div class="auth-wrapper">

  <!-- Left brand / pitch panel -->
  <div class="auth-panel">
    <div class="brand-mark">
      <svg class="roofs" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M4 26L16 14L28 26" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M18 30L28 20L38 30" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" stroke-opacity="0.65"/>
        <rect x="9" y="26" width="14" height="12" rx="1.5" stroke="white" stroke-width="3"/>
      </svg>
      HomeSync
    </div>

    <div class="pitch">
      <h2>One roof.<br>One ledger. No confusion.</h2>
      <p>Track shared expenses, split bills fairly, and keep your household running smoothly — all in one place.</p>
      <div class="stat-row">
        <div><strong>0</strong><span>Disputes this month</span></div>
        <div><strong>100%</strong><span>Settled transparently</span></div>
      </div>
    </div>

    <div class="footnote">HomeSync &middot; Household Expense &amp; Living Management</div>
  </div>

  <!-- Right form panel -->
  <div class="auth-form-side">
    <div class="auth-card">
      <h1>Welcome back</h1>
      <p class="subhead">Log in to your household to pick up where you left off.</p>

      <%
        String errorMessage = (String) request.getAttribute("errorMessage");
      %>
      <% if (errorMessage != null) { %>
        <div class="alert alert-error"><%= errorMessage %></div>
      <% } %>

      <form id="loginForm" action="LoginServlet" method="post" novalidate>

        <div class="field" id="emailField">
          <label for="email">Email address</label>
          <input type="email" id="email" name="email" placeholder="you@example.com" required>
          <div class="error-text">Please enter a valid email address.</div>
        </div>

        <div class="field password-row" id="passwordField">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" placeholder="Enter your password" required minlength="6">
          <button type="button" class="toggle-visibility" id="togglePassword">Show</button>
          <div class="error-text">Password must be at least 6 characters.</div>
        </div>

        <div class="checkbox-row">
          <input type="checkbox" id="remember" name="remember">
          <label for="remember">Keep me signed in on this device</label>
        </div>

        <button type="submit" class="btn-primary">Log In</button>
      </form>

      <div class="divider-row">or</div>

      <p class="switch-line">New to HomeSync? <a href="register.jsp">Create an account</a></p>
    </div>
  </div>

</div>

<script>
  // Show/Hide password
  const pwd = document.getElementById('password');
  const toggleBtn = document.getElementById('togglePassword');
  toggleBtn.addEventListener('click', () => {
    const isHidden = pwd.type === 'password';
    pwd.type = isHidden ? 'text' : 'password';
    toggleBtn.textContent = isHidden ? 'Hide' : 'Show';
  });

  // Basic client-side validation (server-side validation in the Servlet is still required)
  document.getElementById('loginForm').addEventListener('submit', function (e) {
    let valid = true;

    const emailInput = document.getElementById('email');
    const emailField = document.getElementById('emailField');
    const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailInput.value.trim());
    emailField.classList.toggle('has-error', !emailOk);
    if (!emailOk) valid = false;

    const passwordField = document.getElementById('passwordField');
    const passwordOk = pwd.value.length >= 6;
    passwordField.classList.toggle('has-error', !passwordOk);
    if (!passwordOk) valid = false;

    if (!valid) e.preventDefault();
  });
</script>

</body>
</html>
