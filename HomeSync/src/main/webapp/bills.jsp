<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.homesync.util.DBConnection" %>
<%@ page import="com.homesync.util.BillReminderCalculator" %>
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
  <title><%= groupName %> · Bills · HomeSync</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <style>
    .page-wrap { max-width: 700px; margin: 0 auto; padding: 36px 20px 60px; }
    .back-link { font-size: 13.5px; color: var(--ink-soft); display: block; margin-bottom: 22px; }
    .card { background: #fff; border: 1px solid #E2DED4; border-radius: var(--radius); padding: 24px; box-shadow: var(--shadow); margin-bottom: 20px; }
    .card h2 { font-size: 16px; margin: 0 0 16px; }
    .form-row { display: flex; gap: 10px; flex-wrap: wrap; }
    .form-row .field { flex: 1; min-width: 140px; }
    .bill-row { display: flex; justify-content: space-between; align-items: center;
      padding: 12px 0; border-bottom: 1px solid #EFEBE2; }
    .bill-row:last-child { border-bottom: none; }
    .bill-name { font-weight: 600; font-size: 14.5px; }
    .bill-meta { font-size: 12.5px; color: var(--ink-soft); }
    .due-badge { font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 20px; }
    .due-soon { background: #FBEAE8; color: var(--danger); }
    .due-later { background: var(--sage-light); color: var(--sage-dark); }
    .delete-link { color: var(--danger); font-size: 12px; text-decoration: none; font-weight: 600; margin-left: 12px; }
    .empty-state { padding: 20px; text-align: center; color: var(--ink-soft); font-size: 14px; }
  </style>
</head>
<body>
  <div class="page-wrap">
    <a class="back-link" href="expenses.jsp">← Back to expenses</a>
    <h1 style="font-size:22px;"><%= groupName %> — Recurring Bills</h1>
    <p style="color: var(--ink-soft); margin-bottom: 24px;">
      Set up bills that repeat every month, and get flagged when they're coming up soon.
    </p>

    <div class="card">
      <h2>Add a recurring bill</h2>
      <form action="AddBillServlet" method="post">
        <div class="form-row">
          <div class="field">
            <label for="billName">Bill name</label>
            <input type="text" id="billName" name="billName" placeholder="e.g. Rent" required>
          </div>
          <div class="field">
            <label for="amount">Amount (₹, optional)</label>
            <input type="number" step="0.01" id="amount" name="amount" placeholder="e.g. 8000">
          </div>
          <div class="field">
            <label for="dueDay">Due day of month</label>
            <input type="number" id="dueDay" name="dueDay" min="1" max="31" placeholder="e.g. 5" required>
          </div>
        </div>
        <input type="hidden" name="groupId" value="<%= groupId %>">
        <button type="submit" class="btn-primary" style="margin-top:14px;">Add Bill</button>
      </form>
    </div>

    <div class="card">
      <h2>Your household's bills</h2>
      <%
          String sql = "SELECT bill_id, bill_name, amount, due_day FROM recurring_bills WHERE group_id = ? ORDER BY due_day";
          boolean hasBills = false;
          try (Connection conn = DBConnection.getConnection();
               PreparedStatement stmt = conn.prepareStatement(sql)) {
              stmt.setInt(1, groupId);
              ResultSet rs = stmt.executeQuery();
              while (rs.next()) {
                  hasBills = true;
                  int dueDay = rs.getInt("due_day");
                  int daysLeft = BillReminderCalculator.daysUntilDue(dueDay);
                  boolean soon = BillReminderCalculator.isUpcoming(dueDay);
                  double amount = rs.getDouble("amount");
      %>
        <div class="bill-row">
          <div>
            <div class="bill-name"><%= rs.getString("bill_name") %></div>
            <div class="bill-meta">
              Due on day <%= dueDay %> each month
              <% if (amount > 0) { %> &middot; ₹<%= String.format("%.2f", amount) %><% } %>
            </div>
          </div>
          <div>
            <span class="due-badge <%= soon ? "due-soon" : "due-later" %>">
              <%= daysLeft == 0 ? "Due today" : "Due in " + daysLeft + " day" + (daysLeft == 1 ? "" : "s") %>
            </span>
            <a class="delete-link" href="DeleteBillServlet?billId=<%= rs.getInt("bill_id") %>&groupId=<%= groupId %>"
               onclick="return confirm('Remove this recurring bill?');">Remove</a>
          </div>
        </div>
      <%
              }
          } catch (SQLException e) {
              e.printStackTrace();
      %>
        <div class="alert alert-error">Could not load bills right now.</div>
      <%
          }
          if (!hasBills) {
      %>
        <div class="empty-state">No recurring bills set up yet.</div>
      <%
          }
      %>
    </div>
  </div>
</body>
</html>
