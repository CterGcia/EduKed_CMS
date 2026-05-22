use enterprisedata;

CREATE OR REPLACE VIEW VIEWTABLE_FOR_COURSES AS
SELECT 
    c.course_id, 
    c.course_code, 
    c.title, 
    c.description, 
    c.units, 
    CASE s.day_of_week 
        WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed' 
        WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat' 
        WHEN 7 THEN 'Sun' ELSE 'N/A' 
    END AS day_name, 
    IFNULL(CONCAT( 
        CASE s.day_of_week 
            WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed' 
            WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat' 
            WHEN 7 THEN 'Sun' ELSE '?' 
        END, 
        ' ', 
        TIME_FORMAT(s.start_time, '%H:%i'), '-', TIME_FORMAT(s.end_time, '%H:%i') 
    ), 'No Schedule Assigned') AS formatted_schedule, 
    IFNULL(s.room, 'N/A') AS room, 
    IFNULL(CONCAT(i.last_name, ', ', i.first_name), 'Unassigned') AS instructor_name 
FROM Courses c 
LEFT JOIN Schedules s ON c.schedule_id = s.schedule_id 
LEFT JOIN Instructors i ON c.instructor_id = i.instructor_id;