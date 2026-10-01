<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.DBConnection" %>
<%@ page import="java.sql.*" %>
<%
    // Guard: if there's no logged-in user in the session, bounce back to login
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String fullName = (String) session.getAttribute("fullName");
    int userId = (int) session.getAttribute("userId");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .dash-wrap { max-width: 700px; margin: 60px auto; padding: 0 20px; }
    .dash-wrap h1 { font-size: 26px; margin-bottom: 6px; }
    .dash-wrap > p { color: var(--ink-soft); margin-bottom: 26px; }
    .logout-btn { display: inline-block; padding: 10px 18px; background: var(--ink); color: #fff;
      border-radius: 10px; font-weight: 600; font-size: 13.5px; }
    .logout-btn:hover { background: var(--sage-dark); text-decoration: none; }
    .top-row { display: flex; justify-content: space-between; align-items: flex-start; }
    .group-card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius);
      padding: 18px 20px; margin-bottom: 14px; display: flex; justify-content: space-between; align-items: center;
      text-decoration: none; color: inherit; transition: box-shadow 0.15s ease; }
    .group-card:hover { box-shadow: var(--shadow); text-decoration: none; }
    .group-card .name { font-weight: 600; font-size: 15.5px; }
    .group-card .code { font-size: 12.5px; color: var(--ink-soft); margin-top: 3px; }
    .group-card .code strong { color: var(--sage-dark); letter-spacing: 1px; }
    .empty-state { background: #fff; border: 1px dashed #C9C3B4; border-radius: var(--radius);
      padding: 26px; text-align: center; color: var(--ink-soft); font-size: 14px; }
    .add-link { display: inline-block; margin-top: 18px; font-weight: 600; }
  </style>
</head>
<body>
  <div class="dash-wrap">
    <div class="top-row">
      <div>
        <h1>Welcome, <%= fullName %> 👋</h1>
        <p>Here are the households you're part of.</p>
      </div>
      <a class="logout-btn" href="LogoutServlet">Log Out</a>
    </div>

    <%
        String sql = "SELECT g.group_id, g.group_name, g.invite_code, gm.role "
                   + "FROM group_members gm JOIN groups_table g ON gm.group_id = g.group_id "
                   + "WHERE gm.user_id = ?";
        boolean hasGroups = false;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                hasGroups = true;
    %>
        <a class="group-card" href="SelectGroupServlet?groupId=<%= rs.getInt("group_id") %>&groupName=<%= java.net.URLEncoder.encode(rs.getString("group_name"), "UTF-8") %>">
          <div>
            <div class="name"><%= rs.getString("group_name") %></div>
            <div class="code">Invite code: <strong><%= rs.getString("invite_code") %></strong> &middot; <%= rs.getString("role") %></div>
          </div>
          <span style="color: var(--sage-dark); font-weight: 600; font-size: 13px;">Open →</span>
        </a>
    <%
            }
        } catch (SQLException e) {
            e.printStackTrace();
    %>
        <div class="alert alert-error">Could not load your households right now.</div>
    <%
        }

        if (!hasGroups) {
    %>
        <div class="empty-state">You're not part of any household yet.</div>
    <%
        }
    %>

    <a class="add-link" href="groups.jsp">+ Create or join a household</a>
  </div>
</body>
</html>

