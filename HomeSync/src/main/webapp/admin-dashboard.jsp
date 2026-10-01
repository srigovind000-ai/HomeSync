<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.DBConnection" %>
<%@ page import="java.sql.*" %>
<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    if (session.getAttribute("currentGroupId") == null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    int groupId = (int) session.getAttribute("currentGroupId");
    String groupName = (String) session.getAttribute("currentGroupName");
    int userId = (int) session.getAttribute("userId");

    // ---- Authorization check: is the CURRENT user actually an admin of THIS household? ----
    // This is the key idea of an admin dashboard: not just "are you logged in",
    // but "are you allowed to see and do THIS specific thing".
    boolean isAdmin = false;
    String roleCheckSql = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ?";
    try (Connection conn = DBConnection.getConnection();
         PreparedStatement stmt = conn.prepareStatement(roleCheckSql)) {
        stmt.setInt(1, groupId);
        stmt.setInt(2, userId);
        ResultSet rs = stmt.executeQuery();
        if (rs.next() && "admin".equals(rs.getString("role"))) {
            isAdmin = true;
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    if (!isAdmin) {
        // Not an admin -- don't show this page at all, send them back
        response.sendRedirect("expenses.jsp");
        return;
    }

    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Admin · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 700px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 24px; box-shadow: var(--shadow); }
    .card h2 { font-size: 16px; margin: 0 0 16px; }
    .member-row { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #EFEBE2; }
    .member-row:last-child { border-bottom: none; }
    .member-name { font-weight: 600; font-size: 14.5px; }
    .member-email { font-size: 12.5px; color: var(--ink-soft); }
    .role-badge { font-size: 11.5px; font-weight: 700; padding: 3px 10px; border-radius: 20px; text-transform: uppercase; letter-spacing: 0.4px; }
    .role-admin { background: var(--gold); color: #fff; }
    .role-member { background: var(--sage-light); color: var(--sage-dark); }
    .actions { display: flex; gap: 8px; align-items: center; }
    .action-btn { font-size: 12px; font-weight: 600; padding: 6px 12px; border-radius: 8px; border: none; cursor: pointer; font-family: inherit; }
    .promote-btn { background: var(--ink); color: #fff; }
    .remove-btn { background: #FBEAE8; color: var(--danger); }
    .you-tag { font-size: 11px; color: var(--ink-soft); font-style: italic; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Admin Dashboard</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      Manage who's part of this household. Only admins can see this page.
    </p>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } %>

    <div class="card">
      <h2>Members</h2>
      <%
          String sql = "SELECT u.user_id, u.full_name, u.email, gm.role "
                     + "FROM group_members gm JOIN users u ON gm.user_id = u.user_id "
                     + "WHERE gm.group_id = ? ORDER BY gm.role, u.full_name";
          try (Connection conn = DBConnection.getConnection();
               PreparedStatement stmt = conn.prepareStatement(sql)) {
              stmt.setInt(1, groupId);
              ResultSet rs = stmt.executeQuery();
              while (rs.next()) {
                  int memberUserId = rs.getInt("user_id");
                  String role = rs.getString("role");
                  boolean isSelf = (memberUserId == userId);
      %>
        <div class="member-row">
          <div>
            <div class="member-name"><%= rs.getString("full_name") %> <% if (isSelf) { %><span class="you-tag">(you)</span><% } %></div>
            <div class="member-email"><%= rs.getString("email") %></div>
          </div>
          <div class="actions">
            <span class="role-badge <%= role.equals("admin") ? "role-admin" : "role-member" %>"><%= role %></span>
            <% if (!isSelf) { %>
              <form action="UpdateMemberRoleServlet" method="post" style="margin:0;">
                <input type="hidden" name="groupId" value="<%= groupId %>">
                <input type="hidden" name="targetUserId" value="<%= memberUserId %>">
                <button type="submit" class="action-btn promote-btn">
                  <%= role.equals("admin") ? "Demote" : "Promote" %>
                </button>
              </form>
              <form action="RemoveMemberServlet" method="post" style="margin:0;"
                    onsubmit="return confirm('Remove this member from the household?');">
                <input type="hidden" name="groupId" value="<%= groupId %>">
                <input type="hidden" name="targetUserId" value="<%= memberUserId %>">
                <button type="submit" class="action-btn remove-btn">Remove</button>
              </form>
            <% } %>
          </div>
        </div>
      <%
              }
          } catch (SQLException e) {
              e.printStackTrace();
      %>
        <div class="alert alert-error">Could not load members right now.</div>
      <%
          }
      %>
    </div>
  </div>
</body>
</html>
