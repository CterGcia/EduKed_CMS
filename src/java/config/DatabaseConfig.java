package config;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

public class DatabaseConfig implements ServletContextListener {
    public static String derbyDriver;
    public static String derbyUrl;
    public static String derbyUser;
    public static String derbyPassword;
    
    public static String mysqlDriver;
    public static String mysqlUrl;
    public static String mysqlUser;
    public static String mysqlPassword;
    
    public static String postgresDriver;
    public static String postgresUrl;
    public static String postgresUser;
    public static String postgresPassword;
    
    public static String pdfHeaderText;
    public static String pdfFooterText;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        ServletContext ctx = sce.getServletContext();
        derbyDriver = ctx.getInitParameter("derbyDriver");
        derbyUrl = ctx.getInitParameter("derbyUrl");
        derbyUser = ctx.getInitParameter("derbyUser");
        derbyPassword = ctx.getInitParameter("derbyPassword");
        
        mysqlDriver = ctx.getInitParameter("mysqlDriver");
        mysqlUrl = ctx.getInitParameter("mysqlUrl");
        mysqlUser = ctx.getInitParameter("mysqlUser");
        mysqlPassword = ctx.getInitParameter("mysqlPassword");
        
        postgresDriver = ctx.getInitParameter("postgresDriver");
        postgresUrl = ctx.getInitParameter("postgresUrl");
        postgresUser = ctx.getInitParameter("postgresUser");
        postgresPassword = ctx.getInitParameter("postgresPassword");
        
        pdfHeaderText = ctx.getInitParameter("pdfHeaderText");
        pdfFooterText = ctx.getInitParameter("pdfFooterText");

        // Load drivers
        try {
            Class.forName(derbyDriver);
        } catch (ClassNotFoundException e) {
            System.err.println("Failed to load Derby driver: " + e.getMessage());
        }
        try {
            Class.forName(mysqlDriver);
        } catch (ClassNotFoundException e) {
            System.err.println("Failed to load MySQL driver: " + e.getMessage());
        }
        try {
            Class.forName(postgresDriver);
        } catch (ClassNotFoundException e) {
            System.err.println("Failed to load PostgreSQL driver: " + e.getMessage());
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // No teardown required
    }
}
