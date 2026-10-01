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

@WebServlet("/JoinGroupServlet")
public class JoinGroupServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String inviteCode = request.getParameter("inviteCode");

        if (inviteCode == null || inviteCode.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Please enter an invite code.");
            request.getRequestDispatcher("groups.jsp").forward(request, response);
            return;
        }

        String findGroupSql = "SELECT group_id FROM groups_table WHERE invite_code = ?";
        String checkMemberSql = "SELECT group_member_id FROM group_members WHERE group_id = ? AND user_id = ?";
        String insertMemberSql = "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'member')";

        try (Connection conn = DBConnection.getConnection()) {

            int groupId;
            try (PreparedStatement findStmt = conn.prepareStatement(findGroupSql)) {
                findStmt.setString(1, inviteCode.trim().toUpperCase());
                ResultSet rs = findStmt.executeQuery();
                if (!rs.next()) {
                    request.setAttribute("errorMessage", "Invalid invite code. Please check and try again.");
                    request.getRequestDispatcher("groups.jsp").forward(request, response);
                    return;
                }
                groupId = rs.getInt("group_id");
            }

            try (PreparedStatement checkStmt = conn.prepareStatement(checkMemberSql)) {
                checkStmt.setInt(1, groupId);
                checkStmt.setInt(2, userId);
                if (checkStmt.executeQuery().next()) {
                    request.setAttribute("errorMessage", "You're already a member of this household.");
                    request.getRequestDispatcher("groups.jsp").forward(request, response);
                    return;
                }
            }

            try (PreparedStatement insertStmt = conn.prepareStatement(insertMemberSql)) {
                insertStmt.setInt(1, groupId);
                insertStmt.setInt(2, userId);
                insertStmt.executeUpdate();
            }

            response.sendRedirect("dashboard.jsp");

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Something went wrong. Please try again.");
            request.getRequestDispatcher("groups.jsp").forward(request, response);
        }
    }
}
