package config;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

public class DatabaseInitListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("Initializing databases...");
        initDerby();
        initMySQL();
        initPostgreSQL();
        System.out.println("Databases initialization complete.");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // No teardown required
    }

    private void initDerby() {
        if (DatabaseConfig.derbyUrl == null) {
            return;
        }
        try {
            System.out.println("[DEBUG] DatabaseInitListener: initializing Derby at " + DatabaseConfig.derbyUrl);
            Connection conn = null;
            try {
                if (DatabaseConfig.derbyUser != null && DatabaseConfig.derbyPassword != null) {
                    System.out.println("[DEBUG] DatabaseInitListener: using Derby credentials user=" + DatabaseConfig.derbyUser);
                    conn = DriverManager.getConnection(DatabaseConfig.derbyUrl, DatabaseConfig.derbyUser, DatabaseConfig.derbyPassword);
                } else {
                    conn = DriverManager.getConnection(DatabaseConfig.derbyUrl);
                }
                try (Connection _conn = conn) {
                    if (!tableExists(_conn, "Users")) {
                        System.out.println("Creating Derby tables...");
                        try (Statement stmt = _conn.createStatement()) {
                            stmt.execute("CREATE TABLE Users (" +
                                    "    user_id    INT          GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)," +
                                    "    username   VARCHAR(100) NOT NULL," +
                                    "    password   VARCHAR(64)  NOT NULL," +
                                    "    role       VARCHAR(10)  NOT NULL CHECK (role IN ('admin', 'guest'))," +
                                    "    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP," +
                                    "    CONSTRAINT pk_users     PRIMARY KEY (user_id)," +
                                    "    CONSTRAINT uq_username  UNIQUE (username)" +
                                    ")");

                            stmt.execute("CREATE TABLE Sessions (" +
                                    "    session_id   INT GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)," +
                                    "    user_id      INT       NOT NULL," +
                                    "    login_time   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                                    "    logout_time  TIMESTAMP," +
                                    "    CONSTRAINT pk_sessions      PRIMARY KEY (session_id)," +
                                    "    CONSTRAINT fk_session_user  FOREIGN KEY (user_id) REFERENCES Users(user_id)" +
                                    ")");

                            System.out.println("Seeding Derby users...");
                            String adminHash = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";
                            String guestHash = "84983c60f7daadc1cb8698621f802c0d9f9a3c3c295c810748fb048115c186ec";

                            for (int i = 1; i <= 5; i++) {
                                String name = i == 1 ? "admin" : "admin" + i;
                                stmt.execute("INSERT INTO Users (username, password, role) VALUES ('" + name + "', '" + adminHash + "', 'admin')");
                            }
                            for (int i = 1; i <= 46; i++) {
                                stmt.execute("INSERT INTO Users (username, password, role) VALUES ('guest" + i + "', '" + guestHash + "', 'guest')");
                            }
                        }
                    }
                }
            } catch (SQLException e) {
                throw e;
            }
        } catch (SQLException e) {
            System.err.println("Derby auto-initialization error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void initMySQL() {
        if (DatabaseConfig.mysqlUrl == null) {
            return;
        }
        try {
            System.out.println("[DEBUG] DatabaseInitListener: initializing MySQL at " + DatabaseConfig.mysqlUrl + " user: " + DatabaseConfig.mysqlUser);
            try (Connection conn = DriverManager.getConnection(DatabaseConfig.mysqlUrl, DatabaseConfig.mysqlUser, DatabaseConfig.mysqlPassword)) {
                // Check if Semesters exists. If not, build schema.
                if (!tableExists(conn, "Semesters")) {
                    System.out.println("Creating MySQL tables...");
                    try (Statement stmt = conn.createStatement()) {
                        stmt.execute("CREATE TABLE IF NOT EXISTS Semesters ("
                                + "    semester_id  INT AUTO_INCREMENT PRIMARY KEY,"
                                + "    label        VARCHAR(100) NOT NULL,"
                                + "    school_year  VARCHAR(100) NOT NULL,"
                                + "    term         ENUM('1st','2nd','Special') NOT NULL,"
                                + "    is_active    BOOLEAN NOT NULL DEFAULT FALSE"
                                + ")");

                        stmt.execute("CREATE TABLE IF NOT EXISTS Schedules ("
                                + "    schedule_id  INT AUTO_INCREMENT PRIMARY KEY,"
                                + "    day_of_week  TINYINT      NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),"
                                + "    start_time   TIME         NOT NULL,"
                                + "    end_time     TIME         NOT NULL,"
                                + "    room         VARCHAR(100) NOT NULL,"
                                + "    CONSTRAINT chk_schedule_time CHECK (start_time < end_time)"
                                + ")");

                        stmt.execute("CREATE TABLE IF NOT EXISTS Instructors ("
                                + "    instructor_id INT AUTO_INCREMENT PRIMARY KEY,"
                                + "    last_name     VARCHAR(100) NOT NULL,"
                                + "    first_name    VARCHAR(100) NOT NULL,"
                                + "    department    VARCHAR(100) NOT NULL,"
                                + "    user_id       INT"
                                + ")");

                        stmt.execute("CREATE TABLE IF NOT EXISTS Courses ("
                                + "    course_id     INT AUTO_INCREMENT PRIMARY KEY,"
                                + "    course_code   VARCHAR(100) NOT NULL UNIQUE,"
                                + "    title         VARCHAR(100) NOT NULL,"
                                + "    description   TEXT,"
                                + "    units         TINYINT      NOT NULL,"
                                + "    schedule_id   INT,"
                                + "    instructor_id INT,"
                                + "    CONSTRAINT fk_course_schedule   FOREIGN KEY (schedule_id)   REFERENCES Schedules(schedule_id) ON DELETE SET NULL,"
                                + "    CONSTRAINT fk_course_instructor FOREIGN KEY (instructor_id) REFERENCES Instructors(instructor_id) ON DELETE SET NULL"
                                + ")");

                        stmt.execute("CREATE TABLE IF NOT EXISTS Students ("
                                + "    student_id  INT AUTO_INCREMENT PRIMARY KEY,"
                                + "    student_no  VARCHAR(100) NOT NULL UNIQUE,"
                                + "    last_name   VARCHAR(100) NOT NULL,"
                                + "    first_name  VARCHAR(100) NOT NULL,"
                                + "    email       VARCHAR(100) NOT NULL,"
                                + "    year_level  TINYINT      NOT NULL,"
                                + "    program     VARCHAR(100) NOT NULL"
                                + ")");

                        System.out.println("Creating MySQL Views...");
                        stmt.execute("CREATE OR REPLACE VIEW VIEWTABLE_FOR_COURSES AS "
                                + "SELECT "
                                + "    c.course_id, "
                                + "    c.course_code, "
                                + "    c.title, "
                                + "    c.description, "
                                + "    c.units, "
                                + "    CASE s.day_of_week "
                                + "        WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed' "
                                + "        WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat' "
                                + "        WHEN 7 THEN 'Sun' ELSE 'N/A' "
                                + "    END AS day_name, "
                                + "    IFNULL(CONCAT( "
                                + "        CASE s.day_of_week "
                                + "            WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed' "
                                + "            WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat' "
                                + "            WHEN 7 THEN 'Sun' ELSE '?' "
                                + "        END, "
                                + "        ' ', "
                                + "        TIME_FORMAT(s.start_time, '%H:%i'), '-', TIME_FORMAT(s.end_time, '%H:%i') "
                                + "    ), 'No Schedule Assigned') AS formatted_schedule, "
                                + "    IFNULL(s.room, 'N/A') AS room, "
                                + "    IFNULL(CONCAT(i.last_name, ', ', i.first_name), 'Unassigned') AS instructor_name "
                                + "FROM Courses c "
                                + "LEFT JOIN Schedules  s ON c.schedule_id   = s.schedule_id "
                                + "LEFT JOIN Instructors i ON c.instructor_id = i.instructor_id");

                        stmt.execute("CREATE OR REPLACE VIEW VIEWTABLE_FOR_STUDENTS AS "
                                + "SELECT "
                                + "    student_id, "
                                + "    student_no, "
                                + "    last_name, "
                                + "    first_name, "
                                + "    CONCAT(last_name, ', ', first_name) AS student_name, "
                                + "    email, "
                                + "    year_level, "
                                + "    program "
                                + "FROM Students");

                        stmt.execute("CREATE OR REPLACE VIEW VIEWTABLE_FOR_INSTRUCTORS AS "
                                + "SELECT "
                                + "    i.instructor_id, "
                                + "    i.last_name, "
                                + "    i.first_name, "
                                + "    i.department, "
                                + "    IFNULL(GROUP_CONCAT(c.course_code ORDER BY c.course_code SEPARATOR ', '), 'No courses assigned') AS courses_taught "
                                + "FROM Instructors i "
                                + "LEFT JOIN Courses c ON c.instructor_id = i.instructor_id "
                                + "GROUP BY i.instructor_id, i.last_name, i.first_name, i.department");

                        System.out.println("Seeding MySQL records...");
                        stmt.execute("INSERT INTO Semesters (label, school_year, term, is_active) VALUES "
                                + "('1st Semester 2024-2025', '2024-2025', '1st', FALSE), "
                                + "('2nd Semester 2024-2025', '2024-2025', '2nd', TRUE), "
                                + "('Summer 2025',            '2024-2025', 'Special', FALSE)");

                        stmt.execute("INSERT INTO Schedules (day_of_week, start_time, end_time, room) VALUES "
                                + "(1, '07:30:00', '09:00:00', 'GV 101'), "
                                + "(1, '09:00:00', '10:30:00', 'GV 102'), "
                                + "(2, '07:30:00', '09:00:00', 'GV 201'), "
                                + "(2, '13:00:00', '14:30:00', 'GV 202'), "
                                + "(3, '10:30:00', '12:00:00', 'Lab 301'), "
                                + "(3, '13:00:00', '14:30:00', 'Lab 302'), "
                                + "(4, '07:30:00', '09:00:00', 'GV 103'), "
                                + "(4, '09:00:00', '10:30:00', 'GV 104'), "
                                + "(5, '10:30:00', '12:00:00', 'Lab 401'), "
                                + "(5, '13:00:00', '14:30:00', 'Lab 402')");

                        stmt.execute("INSERT INTO Instructors (last_name, first_name, department) VALUES "
                                + "('Reyes',     'Maria',    'Computer Science'), "
                                + "('Santos',    'Jose',     'Information Technology'), "
                                + "('Cruz',      'Ana',      'Computer Science'), "
                                + "('Garcia',    'Luis',     'Information Systems'), "
                                + "('Mendoza',   'Clara',    'Computer Science'), "
                                + "('Torres',    'Ramon',    'Information Technology'), "
                                + "('Flores',    'Elena',    'Information Systems'), "
                                + "('Bautista',  'Marco',    'Computer Science'), "
                                + "('Aquino',    'Rosa',     'Information Technology'), "
                                + "('Villanueva','Diego',    'Information Systems')");

                        stmt.execute("INSERT INTO Courses (course_code, title, description, units, schedule_id, instructor_id) VALUES "
                                + "('ICS2601', 'Data Structures and Algorithms', 'Fundamental data structures and algorithm analysis.', 3, 1, 1), "
                                + "('ICS2602', 'Database Management Systems',   'Relational databases, SQL, normalization.',           3, 2, 2), "
                                + "('ICS2603', 'Operating Systems',             'Process management, memory, file systems.',           3, 3, 3), "
                                + "('ICS2604', 'Computer Networks',             'TCP/IP, routing, network security fundamentals.',     3, 4, 4), "
                                + "('ICS2605', 'Software Engineering',          'SDLC, requirements, design patterns, testing.',      3, 5, 5), "
                                + "('ICS2606', 'Web Development',               'HTML, CSS, JavaScript, server-side technologies.',   3, 6, 6), "
                                + "('ICS2607', 'Artificial Intelligence',       'Search algorithms, machine learning basics.',        3, 7, 7), "
                                + "('ICS2608', 'Human-Computer Interaction',    'UI/UX design principles and usability testing.',     2, 8, 8), "
                                + "('ICS2609', 'Advanced Programming',          'Java EE, servlets, JSP, multi-tier architecture.',  3, 9, 9), "
                                + "('ICS2610', 'Cybersecurity Fundamentals',    'Threats, cryptography, secure coding practices.',   3, 10, 10)");

                        stmt.execute("INSERT INTO Students (student_no, last_name, first_name, email, year_level, program) VALUES "
                                + "('2021-00001', 'Aguilar',   'Sofia',    'saguilar@student.edu',   3, 'BSCS'), "
                                + "('2021-00002', 'Bernardo',  'Miguel',   'mbernardo@student.edu',  3, 'BSIT'), "
                                + "('2021-00003', 'Castillo',  'Andrea',   'acastillo@student.edu',  3, 'BSIS'), "
                                + "('2021-00004', 'Dela Cruz', 'Carlo',    'cdelacruz@student.edu',  2, 'BSCS'), "
                                + "('2021-00005', 'Espiritu',  'Lara',     'lespiritu@student.edu',  2, 'BSIT'), "
                                + "('2021-00006', 'Fernandez', 'Paolo',    'pfernandez@student.edu', 4, 'BSCS'), "
                                + "('2021-00007', 'Gonzales',  'Nina',     'ngonzales@student.edu',  4, 'BSIS'), "
                                + "('2021-00008', 'Hernandez', 'Rico',     'rhernandez@student.edu', 1, 'BSIT'), "
                                + "('2021-00009', 'Ilustre',   'Camille',  'cilustre@student.edu',   1, 'BSCS'), "
                                + "('2021-00010', 'Javier',    'Francis',  'fjavier@student.edu',    3, 'BSIT'), "
                                + "('2021-00011', 'Kabigting', 'Tricia',   'tkabigting@student.edu', 2, 'BSCS'), "
                                + "('2021-00012', 'Lopez',     'Andrei',   'alopez@student.edu',     3, 'BSIS'), "
                                + "('2021-00013', 'Macaraeg',  'Kyla',     'kmacaraeg@student.edu',  4, 'BSCS'), "
                                + "('2021-00014', 'Navarro',   'Dino',     'dnavarro@student.edu',   2, 'BSIT'), "
                                + "('2021-00015', 'Ocampo',    'Bea',      'bocampo@student.edu',    1, 'BSIS'), "
                                + "('2021-00016', 'Padilla',   'Gio',      'gpadilla@student.edu',   3, 'BSCS'), "
                                + "('2021-00017', 'Quezon',    'Mariel',   'mquezon@student.edu',    4, 'BSIT'), "
                                + "('2021-00018', 'Ramos',     'Ethan',    'eramos@student.edu',     2, 'BSCS'), "
                                + "('2021-00019', 'Soriano',   'Alyssa',   'asoriano@student.edu',   1, 'BSIS'), "
                                + "('2021-00020', 'Tan',       'Marco',    'mtan@student.edu',       3, 'BSIT')");
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("MySQL auto-initialization error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void initPostgreSQL() {
        if (DatabaseConfig.postgresUrl == null) {
            return;
        }
        try {
            System.out.println("[DEBUG] DatabaseInitListener: initializing PostgreSQL at " + DatabaseConfig.postgresUrl + " user: " + DatabaseConfig.postgresUser);
            try (Connection conn = DriverManager.getConnection(DatabaseConfig.postgresUrl, DatabaseConfig.postgresUser, DatabaseConfig.postgresPassword)) {
                if (!tableExists(conn, "ReportLogs")) {
                    System.out.println("Creating PostgreSQL tables...");
                    try (Statement stmt = conn.createStatement()) {
                        stmt.execute("CREATE TABLE IF NOT EXISTS ReportLogs ("
                                + "    report_id     BIGSERIAL    PRIMARY KEY,"
                                + "    generated_by  VARCHAR(100) NOT NULL,"
                                + "    report_type   VARCHAR(100) NOT NULL,"
                                + "    filename      VARCHAR(200) NOT NULL,"
                                + "    generated_at  TIMESTAMP    NOT NULL DEFAULT NOW()"
                                + ")");

                        stmt.execute("CREATE TABLE IF NOT EXISTS ErrorLogs ("
                                + "    error_id    BIGSERIAL    PRIMARY KEY,"
                                + "    error_code  VARCHAR(500) NOT NULL,"
                                + "    message     TEXT,"
                                + "    stack       TEXT,"
                                + "    timestamp   TIMESTAMP    NOT NULL DEFAULT NOW()"
                                + ")");

                        System.out.println("Seeding PostgreSQL logs...");
                        stmt.execute("INSERT INTO ReportLogs (generated_by, report_type, filename) VALUES "
                                + "('admin', 'ALL_RECORDS',   'ALLUSERS_20260522093000.pdf'), "
                                + "('admin', 'ADMIN_OWN',     'ADMINRECORDS_20260522093001.pdf'), "
                                + "('admin', 'COURSE_CATALOG','COURSECATALOG_20260522093002.pdf')");

                        stmt.execute("INSERT INTO ErrorLogs (error_code, message, stack) VALUES "
                                + "('INIT', 'System initialized successfully.', '')");
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("PostgreSQL auto-initialization error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private boolean tableExists(Connection conn, String tableName) {
        try {
            DatabaseMetaData dbmd = conn.getMetaData();
            try (ResultSet rs = dbmd.getTables(null, null, tableName.toUpperCase(), null)) {
                if (rs.next()) {
                    return true;
                }
            }
            try (ResultSet rs = dbmd.getTables(null, null, tableName.toLowerCase(), null)) {
                if (rs.next()) {
                    return true;
                }
            }
            try (ResultSet rs = dbmd.getTables(null, null, tableName, null)) {
                if (rs.next()) {
                    return true;
                }
            }
        } catch (SQLException e) {
            // fall back
        }
        return false;
    }
}
