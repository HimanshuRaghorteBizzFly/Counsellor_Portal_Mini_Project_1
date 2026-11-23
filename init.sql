-- =====================================================================
-- Counsellor Portal - Database Initialization Script
-- Executed on initial container launch for MySQL
-- =====================================================================

CREATE DATABASE IF NOT EXISTS counsellor_db;
USE counsellor_db;

-- Initial Course data schema
CREATE TABLE IF NOT EXISTS course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(255) NOT NULL
);

-- Seed essential courses idempotently
INSERT INTO course (course_name)
SELECT 'Java Full Stack' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM course WHERE course_name = 'Java Full Stack')
UNION ALL
SELECT 'Python Full Stack' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM course WHERE course_name = 'Python Full Stack')
UNION ALL
SELECT 'DevOps & Cloud (AWS)' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM course WHERE course_name = 'DevOps & Cloud (AWS)')
UNION ALL
SELECT 'Data Science & AI' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM course WHERE course_name = 'Data Science & AI')
UNION ALL
SELECT 'Full Stack Web Development' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM course WHERE course_name = 'Full Stack Web Development');
