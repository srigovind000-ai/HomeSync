package com.homesync.servlet;

import com.homesync.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

@WebServlet("/CreateGroupServlet")
public class CreateGroupServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no 0/O/1/I to avoid confusion

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String groupName = request.getParameter("groupName");

        if (groupName == null || groupName.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Please enter a household name.");
            request.getRequestDispatcher("groups.jsp").forward(request, response);
            return;
        }

        String inviteCode = generateInviteCode();

        String insertGroupSql = "INSERT INTO groups_table (group_name, invite_code, created_by) VALUES (?, ?, ?)";
        String insertMemberSql = "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')";

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); // both inserts should succeed together, or neither should

            int newGroupId;
            try (PreparedStatement groupStmt = conn.prepareStatement(insertGroupSql, Statement.RETURN_GENERATED_KEYS)) {
                groupStmt.setString(1, groupName.trim());
                groupStmt.setString(2, inviteCode);
                groupStmt.setInt(3, userId);
                groupStmt.executeUpdate();

                ResultSet keys = groupStmt.getGeneratedKeys();
                keys.next();
                newGroupId = keys.getInt(1);
            }

            try (PreparedStatement memberStmt = conn.prepareStatement(insertMemberSql)) {
                memberStmt.setInt(1, newGroupId);
                memberStmt.setInt(2, userId);
                memberStmt.executeUpdate();
            }

            conn.commit();
            response.sendRedirect("dashboard.jsp");

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Could not create household. Please try again.");
            request.getRequestDispatcher("groups.jsp").forward(request, response);
        }
    }

    private String generateInviteCode() {
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 6; i++) {
            sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
        }
        return sb.toString();
    }
}
