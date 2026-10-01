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

@WebServlet("/RemoveMemberServlet")
public class RemoveMemberServlet extends HttpServlet {

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

                // Re-check: is the person making this request ACTUALLY an admin
                // of THIS household? Never trust that the button was only
                // shown to admins in the JSP -- someone could submit this
                // form directly without going through the page at all.
                if (!isAdmin(conn, groupId, currentUserId)) {
                    response.sendRedirect("expenses.jsp");
                    return;
                }

                // Safeguard: don't allow removing the last remaining admin,
                // which would leave the household with no one able to manage it.
                String targetRoleSql = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ?";
                String targetRole = null;
                try (PreparedStatement stmt = conn.prepareStatement(targetRoleSql)) {
                    stmt.setInt(1, groupId);
                    stmt.setInt(2, targetUserId);
                    ResultSet rs = stmt.executeQuery();
                    if (rs.next()) targetRole = rs.getString("role");
                }

                if ("admin".equals(targetRole) && countAdmins(conn, groupId) <= 1) {
                    request.setAttribute("errorMessage", "Cannot remove the only admin left in this household.");
                    request.getRequestDispatcher("admin-dashboard.jsp").forward(request, response);
                    return;
                }

                String deleteSql = "DELETE FROM group_members WHERE group_id = ? AND user_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(deleteSql)) {
                    stmt.setInt(1, groupId);
                    stmt.setInt(2, targetUserId);
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
        String sql = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            ResultSet rs = stmt.executeQuery();
            return rs.next() && "admin".equals(rs.getString("role"));
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
