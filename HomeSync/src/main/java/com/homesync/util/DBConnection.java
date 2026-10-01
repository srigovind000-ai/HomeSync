package com.homesync.util;
 
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
 
/**
 * Small helper class so every Servlet doesn't repeat the same
 * connection string. Update DB_URL / DB_USER / DB_PASSWORD to match
 * your own MySQL setup.
 */
public class DBConnection {
 
    private static final String DB_URL = "jdbc:mysql://localhost:3306/homesync?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String DB_USER = "root";        // change if your MySQL user is different
    private static final String DB_PASSWORD = "yourpassword"; // change to your actual MySQL password
 
    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC Driver not found. Did you add the Connector/J jar to Build Path?", e);
        }
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }
}