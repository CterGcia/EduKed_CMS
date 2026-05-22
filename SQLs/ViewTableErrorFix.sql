CREATE OR REPLACE VIEW VIEWTABLE_FOR_STUDENTS AS
SELECT 
    student_id, 
    student_no, 
    last_name, 
    first_name, 
    CONCAT(last_name, ', ', first_name) AS student_name, 
    email, 
    year_level, 
    program 
FROM Students;

CREATE OR REPLACE VIEW VIEWTABLE_FOR_INSTRUCTORS AS
SELECT 
    i.instructor_id, 
    i.last_name, 
    i.first_name, 
    i.department, 
    IFNULL(GROUP_CONCAT(c.course_code ORDER BY c.course_code SEPARATOR ', '), 'No courses assigned') AS courses_taught 
FROM Instructors i 
LEFT JOIN Courses c ON c.instructor_id = i.instructor_id 
GROUP BY i.instructor_id, i.last_name, i.first_name, i.department;