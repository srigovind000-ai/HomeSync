<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%--
  register.jsp
  Front-end only for now. Wire this up later to a RegisterServlet that:
    - reads name, email, password from request.getParameter(...)
    - checks the email isn't already used (SELECT ... WHERE email = ?)
    - inserts a new row into the `users` table via JDBC (hash the password!)
    - redirects to login.jsp with a success message
--%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Create Account · HomeSync</title>
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
      <h2>Set up your household in under a minute.</h2>
      <p>Create your account, then create or join a group with a simple invite code. No spreadsheets, no chasing people for money.</p>
      <div class="stat-row">
        <div><strong>17</strong><span>Features built in</span></div>
        <div><strong>1</strong><span>Place for everything</span></div>
      </div>
    </div>

    <div class="footnote">HomeSync &middot; Household Expense &amp; Living Management</div>
  </div>

  <!-- Right form panel -->
  <div class="auth-form-side">
    <div class="auth-card">
      <h1>Create your account</h1>
      <p class="subhead">It only takes a minute to get started.</p>

      <%
        String errorMessage = (String) request.getAttribute("errorMessage");
      %>
      <% if (errorMessage != null) { %>
        <div class="alert alert-error"><%= errorMessage %></div>
      <% } %>

      <form id="registerForm" action="RegisterServlet" method="post" novalidate>

        <div class="field" id="nameField">
          <label for="fullName">Full name</label>
          <input type="text" id="fullName" name="fullName" placeholder="e.g. Sri Govind" required>
          <div class="error-text">Please enter your name.</div>
        </div>

        <div class="field" id="emailField">
          <label for="email">Email address</label>
          <input type="email" id="email" name="email" placeholder="you@example.com" required>
          <div class="error-text">Please enter a valid email address.</div>
        </div>

        <div class="field password-row" id="passwordField">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" placeholder="At least 6 characters" required minlength="6">
          <button type="button" class="toggle-visibility" id="togglePassword">Show</button>
          <div class="error-text">Password must be at least 6 characters.</div>
        </div>

        <div class="field password-row" id="confirmField">
          <label for="confirmPassword">Confirm password</label>
          <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Re-enter your password" required>
          <div class="error-text">Passwords do not match.</div>
        </div>

        <button type="submit" class="btn-primary">Create Account</button>
      </form>

      <div class="divider-row">or</div>

      <p class="switch-line">Already have an account? <a href="login.jsp">Log in</a></p>
    </div>
  </div>

</div>

<script>
  const pwd = document.getElementById('password');
  const toggleBtn = document.getElementById('togglePassword');
  toggleBtn.addEventListener('click', () => {
    const isHidden = pwd.type === 'password';
    pwd.type = isHidden ? 'text' : 'password';
    toggleBtn.textContent = isHidden ? 'Hide' : 'Show';
  });

  document.getElementById('registerForm').addEventListener('submit', function (e) {
    let valid = true;

    const nameField = document.getElementById('nameField');
    const nameOk = document.getElementById('fullName').value.trim().length > 1;
    nameField.classList.toggle('has-error', !nameOk);
    if (!nameOk) valid = false;

    const emailField = document.getElementById('emailField');
    const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(document.getElementById('email').value.trim());
    emailField.classList.toggle('has-error', !emailOk);
    if (!emailOk) valid = false;

    const passwordField = document.getElementById('passwordField');
    const passwordOk = pwd.value.length >= 6;
    passwordField.classList.toggle('has-error', !passwordOk);
    if (!passwordOk) valid = false;

    const confirmField = document.getElementById('confirmField');
    const confirmOk = document.getElementById('confirmPassword').value === pwd.value && pwd.value.length > 0;
    confirmField.classList.toggle('has-error', !confirmOk);
    if (!confirmOk) valid = false;

    if (!valid) e.preventDefault();
  });
</script>

</body>
</html>
