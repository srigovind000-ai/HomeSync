<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String fullName = (String) session.getAttribute("fullName");
    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Groups · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 900px; margin: 0 auto; padding: 40px 20px 60px; }
    .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 32px; }
    .page-header h1 { font-size: 24px; margin: 0; }
    .page-header a { font-size: 14px; }
    .card-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
    @media (max-width: 700px) { .card-grid { grid-template-columns: 1fr; } }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius);
      padding: 28px; box-shadow: var(--shadow); }
    .card h2 { font-size: 18px; margin: 0 0 6px; }
    .card p.hint { color: var(--ink-soft); font-size: 13.5px; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <div class="page-header">
      <h1>Hi, <%= fullName %> 👋</h1>
      <a href="LogoutServlet">Log Out</a>
    </div>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } %>

    <div class="card-grid">

      <div class="card">
        <h2>Create a new household</h2>
        <p class="hint">Start a group and get an invite code to share with your housemates.</p>
        <form action="CreateGroupServlet" method="post">
          <div class="field">
            <label for="groupName">Household name</label>
            <input type="text" id="groupName" name="groupName" placeholder="e.g. Flat 4B" required>
          </div>
          <button type="submit" class="btn-primary">Create Household</button>
        </form>
      </div>

      <div class="card">
        <h2>Join an existing household</h2>
        <p class="hint">Enter the invite code your housemate shared with you.</p>
        <form action="JoinGroupServlet" method="post">
          <div class="field">
            <label for="inviteCode">Invite code</label>
            <input type="text" id="inviteCode" name="inviteCode" placeholder="e.g. A1B2C3" required>
          </div>
          <button type="submit" class="btn-primary">Join Household</button>
        </form>
      </div>

    </div>
  </div>
</body>
</html>
