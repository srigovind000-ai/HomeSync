package com.homesync.servlet;

import com.homesync.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        // Basic server-side validation (never trust the client-side JS alone)
        if (fullName == null || fullName.trim().isEmpty()
                || email == null || email.trim().isEmpty()
                || password == null || password.length() < 6) {
            request.setAttribute("errorMessage", "Please fill all fields correctly.");
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            // Check if email is already registered
            String checkSql = "SELECT user_id FROM users WHERE email = ?";
            try (PreparedStatement checkStmt = conn.prepareStatement(checkSql)) {
                checkStmt.setString(1, email);
                if (checkStmt.executeQuery().next()) {
                    request.setAttribute("errorMessage", "An account with this email already exists.");
                    request.getRequestDispatcher("register.jsp").forward(request, response);
                    return;
                }
            }

            // Insert new user with a hashed password
            String insertSql = "INSERT INTO users (full_name, email, password) VALUES (?, ?, ?)";
            try (PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
                insertStmt.setString(1, fullName.trim());
                insertStmt.setString(2, email.trim());
                insertStmt.setString(3, hashPassword(password));
                insertStmt.executeUpdate();
            }

            // Success -> send them to the login page
            response.sendRedirect("login.jsp?registered=true");

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Something went wrong. Please try again.");
            request.getRequestDispatcher("register.jsp").forward(request, response);
        }
    }

    /** Simple SHA-256 hash so we never store plain-text passwords. */
    private String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(password.getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
