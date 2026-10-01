package com.homesync.servlet;

import com.homesync.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet("/UpdateMemberRoleServlet")
public class UpdateMemberRoleServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int currentUserId = (int) session.getAttribute("userId");

        try {
            int groupId = Integer.parseInt(request.getParameter("groupId"));
            int targetUserId = Integer.parseInt(request.getParameter("targetUserId"));

            try (Connection conn = DBConnection.getConnection()) {

                if (!isAdmin(conn, groupId, currentUserId)) {
                    response.sendRedirect("expenses.jsp");
                    return;
                }

                String currentRole = getRole(conn, groupId, targetUserId);
                if (currentRole == null) {
                    response.sendRedirect("admin-dashboard.jsp");
                    return;
                }

                String newRole = currentRole.equals("admin") ? "member" : "admin";

                // Safeguard: if demoting an admin, make sure at least one
                // admin remains after the change.
                if (currentRole.equals("admin") && countAdmins(conn, groupId) <= 1) {
                    request.setAttribute("errorMessage", "Cannot demote the only admin left in this household.");
                    request.getRequestDispatcher("admin-dashboard.jsp").forward(request, response);
                    return;
                }

                String updateSql = "UPDATE group_members SET role = ? WHERE group_id = ? AND user_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(updateSql)) {
                    stmt.setString(1, newRole);
                    stmt.setInt(2, groupId);
                    stmt.setInt(3, targetUserId);
                    stmt.executeUpdate();
                }
            }

            response.sendRedirect("admin-dashboard.jsp");

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            response.sendRedirect("admin-dashboard.jsp");
        }
    }

    private boolean isAdmin(Connection conn, int groupId, int userId) throws SQLException {
        String role = getRole(conn, groupId, userId);
        return "admin".equals(role);
    }

    private String getRole(Connection conn, int groupId, int userId) throws SQLException {
        String sql = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            ResultSet rs = stmt.executeQuery();
            return rs.next() ? rs.getString("role") : null;
        }
    }

    private int countAdmins(Connection conn, int groupId) throws SQLException {
        String sql = "SELECT COUNT(*) AS admin_count FROM group_members WHERE group_id = ? AND role = 'admin'";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            return rs.next() ? rs.getInt("admin_count") : 0;
        }
    }
}
