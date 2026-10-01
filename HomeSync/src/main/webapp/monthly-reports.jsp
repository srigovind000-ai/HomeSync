<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.DBConnection" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
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
    String errorMessage = null;
    List<String> months = new ArrayList<>();

    try (Connection conn = DBConnection.getConnection()) {
        String monthsSql = "SELECT DISTINCT DATE_FORMAT(expense_date, '%Y-%m') AS month "
                          + "FROM expenses WHERE group_id = ? ORDER BY month DESC";
        try (PreparedStatement stmt = conn.prepareStatement(monthsSql)) {
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                months.add(rs.getString("month"));
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
        errorMessage = "Could not load reports right now.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= groupName %> · Monthly Reports · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 780px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 24px; box-shadow: var(--shadow); margin-bottom: 20px; }
    .month-title { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 16px; }
    .month-title h2 { font-size: 18px; margin: 0; }
    .month-total { font-size: 20px; font-weight: 700; font-family: 'Poppins', sans-serif; color: var(--sage-dark); }
    .breakdown-cols { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    @media (max-width: 600px) { .breakdown-cols { grid-template-columns: 1fr; } }
    .breakdown-cols h3 { font-size: 12.5px; text-transform: uppercase; letter-spacing: 0.4px; color: var(--ink-soft); margin: 0 0 10px; }
    .row-line { display: flex; justify-content: space-between; padding: 6px 0; font-size: 13.5px; border-bottom: 1px solid #EFEBE2; }
    .row-line:last-child { border-bottom: none; }
    .empty-state { padding: 30px; text-align: center; color: var(--ink-soft); font-size: 14px; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Monthly Reports</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      A month-by-month summary of spending, broken down by category and by member.
    </p>

    <% if (errorMessage != null) { %>
      <div class="alert alert-error"><%= errorMessage %></div>
    <% } else if (months.isEmpty()) { %>
      <div class="card"><div class="empty-state">No expenses logged yet — reports will appear once there's data.</div></div>
    <% } else {
        for (String month : months) {
            double monthTotal = 0;
            List<String> catNames = new ArrayList<>();
            List<Double> catTotals = new ArrayList<>();
            List<String> memberNames = new ArrayList<>();
            List<Double> memberTotals = new ArrayList<>();

            try (Connection conn = DBConnection.getConnection()) {

                String totalSql = "SELECT SUM(amount) AS total FROM expenses "
                                 + "WHERE group_id = ? AND DATE_FORMAT(expense_date, '%Y-%m') = ?";
                try (PreparedStatement stmt = conn.prepareStatement(totalSql)) {
                    stmt.setInt(1, groupId);
                    stmt.setString(2, month);
                    ResultSet rs = stmt.executeQuery();
                    if (rs.next()) monthTotal = rs.getDouble("total");
                }

                String catSql = "SELECT c.category_name, SUM(e.amount) AS total FROM expenses e "
                               + "JOIN expense_categories c ON e.category_id = c.category_id "
                               + "WHERE e.group_id = ? AND DATE_FORMAT(e.expense_date, '%Y-%m') = ? "
                               + "GROUP BY c.category_name ORDER BY total DESC";
                try (PreparedStatement stmt = conn.prepareStatement(catSql)) {
                    stmt.setInt(1, groupId);
                    stmt.setString(2, month);
                    ResultSet rs = stmt.executeQuery();
                    while (rs.next()) {
                        catNames.add(rs.getString("category_name"));
                        catTotals.add(rs.getDouble("total"));
                    }
                }

                String memberSql = "SELECT u.full_name, SUM(e.amount) AS total FROM expenses e "
                                  + "JOIN users u ON e.paid_by = u.user_id "
                                  + "WHERE e.group_id = ? AND DATE_FORMAT(e.expense_date, '%Y-%m') = ? "
                                  + "GROUP BY u.full_name ORDER BY total DESC";
                try (PreparedStatement stmt = conn.prepareStatement(memberSql)) {
                    stmt.setInt(1, groupId);
                    stmt.setString(2, month);
                    ResultSet rs = stmt.executeQuery();
                    while (rs.next()) {
                        memberNames.add(rs.getString("full_name"));
                        memberTotals.add(rs.getDouble("total"));
                    }
                }

            } catch (SQLException e) {
                e.printStackTrace();
            }
    %>
      <div class="card">
        <div class="month-title">
          <h2><%= month %></h2>
          <span class="month-total">₹<%= String.format("%.2f", monthTotal) %></span>
        </div>
        <div class="breakdown-cols">
          <div>
            <h3>By Category</h3>
            <% for (int i = 0; i < catNames.size(); i++) { %>
              <div class="row-line"><span><%= catNames.get(i) %></span><span>₹<%= String.format("%.2f", catTotals.get(i)) %></span></div>
            <% } %>
          </div>
          <div>
            <h3>By Member</h3>
            <% for (int i = 0; i < memberNames.size(); i++) { %>
              <div class="row-line"><span><%= memberNames.get(i) %></span><span>₹<%= String.format("%.2f", memberTotals.get(i)) %></span></div>
            <% } %>
          </div>
        </div>
      </div>
    <%
        }
    } %>
  </div>
</body>
</html>
