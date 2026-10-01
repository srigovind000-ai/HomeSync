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
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Shopping List · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 620px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .add-form { display: flex; gap: 10px; margin-bottom: 24px; }
    .add-form input[type=text] { flex: 1; padding: 12px 14px; border: 1.5px solid #E2DED4;
      border-radius: 10px; font-size: 14.5px; font-family: inherit; }
    .add-form button { padding: 12px 20px; background: var(--ink); color: #fff; border: none;
      border-radius: 10px; font-weight: 600; font-size: 14px; cursor: pointer; font-family: inherit; }
    .add-form button:hover { background: var(--sage-dark); }
    .item-row { display: flex; align-items: center; gap: 12px; background: #fff; border: 1px solid #E2DED4;
      border-radius: 12px; padding: 12px 16px; margin-bottom: 8px; }
    .item-row.checked { opacity: 0.55; }
    .item-row.checked .item-name { text-decoration: line-through; }
    .item-name { flex: 1; font-size: 14.5px; }
    .item-meta { font-size: 11.5px; color: var(--ink-soft); }
    .checkbox-toggle { width: 20px; height: 20px; cursor: pointer; accent-color: var(--sage); }
    .delete-link { color: var(--danger); font-size: 12px; text-decoration: none; font-weight: 600; }
    .empty-state { padding: 24px; text-align: center; color: var(--ink-soft); font-size: 14px; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Shopping List</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      Everyone in this household sees the same list — add something once, no duplicate buying.
    </p>

    <form class="add-form" action="AddShoppingItemServlet" method="post">
      <input type="text" name="itemName" placeholder="e.g. Milk, dish soap, bread..." required>
      <input type="hidden" name="groupId" value="<%= groupId %>">
      <button type="submit">Add</button>
    </form>

    <%
        String sql = "SELECT si.item_id, si.item_name, si.is_purchased, si.created_at, u.full_name "
                   + "FROM shopping_list_items si "
                   + "JOIN users u ON si.added_by = u.user_id "
                   + "WHERE si.group_id = ? "
                   + "ORDER BY si.is_purchased ASC, si.created_at DESC";
        boolean hasItems = false;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                hasItems = true;
                boolean purchased = rs.getBoolean("is_purchased");
                int itemId = rs.getInt("item_id");
    %>
        <div class="item-row <%= purchased ? "checked" : "" %>">
          <form action="ToggleShoppingItemServlet" method="post" style="margin:0;">
            <input type="hidden" name="itemId" value="<%= itemId %>">
            <input type="hidden" name="groupId" value="<%= groupId %>">
            <input type="checkbox" class="checkbox-toggle" onchange="this.form.submit()" <%= purchased ? "checked" : "" %>>
          </form>
          <div style="flex:1;">
            <div class="item-name"><%= rs.getString("item_name") %></div>
            <div class="item-meta">added by <%= rs.getString("full_name") %></div>
          </div>
          <a class="delete-link" href="DeleteShoppingItemServlet?itemId=<%= itemId %>&groupId=<%= groupId %>"
             onclick="return confirm('Remove this item from the list?');">Remove</a>
        </div>
    <%
            }
        } catch (SQLException e) {
            e.printStackTrace();
    %>
        <div class="alert alert-error">Could not load the shopping list right now.</div>
    <%
        }
        if (!hasItems) {
    %>
        <div class="empty-state">The list is empty — add the first item above.</div>
    <%
        }
    %>
  </div>
</body>
</html>
