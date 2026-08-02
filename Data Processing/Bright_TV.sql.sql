-- Databricks notebook source
--Upload data and preview tables
SELECT *
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
LIMIT 10;

--How big is the data? (row count vs distinct users)
-- Total rows
SELECT COUNT(*) AS number_of_rows
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;
-- No of Rows= 5375

-- Distinct subscribers
SELECT COUNT(DISTINCT UserID) AS number_subs
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;
-- No of Subscribers= 5375  (equal to row count = no duplicate users)

--Null and duplicate checks (profiles)
-- Any rows where UserID is null?
SELECT COUNT(*) AS cnt
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
WHERE UserID IS NULL;

--Gender checks and standardization
-- Check Duplicates
SELECT UserID, COUNT(*) AS duplicate_count
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
GROUP BY UserID
HAVING COUNT(*) > 1;

-- Distinct gender values  
SELECT DISTINCT Gender
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;

-- How many are blank?
SELECT COUNT(*) AS cnt
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
WHERE Gender IS NULL OR Gender = '';

-- Create gender into clean values
  SELECT
  COUNT(*) AS cnt,
  COUNT(DISTINCT UserID) AS subs,
  CASE
    WHEN Gender = ' ' THEN 'Unkown'
    WHEN Gender = 'None' THEN 'Unkown'
    WHEN Gender ILIKE 'Unkown' THEN 'Unknown'
    ELSE Gender
  END AS gender
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
GROUP BY CASE
    WHEN Gender = ' ' THEN 'Unkown'
    WHEN Gender = 'None' THEN 'Unkown'
    WHEN Gender ILIKE 'Unkown' THEN 'Unknown'
    ELSE Gender
    END;

--Race checks and standardization
-- Distinct race values
SELECT DISTINCT Race
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;
 
-- Count blanks
SELECT COUNT(*) AS num_rows
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
WHERE Race IS NULL OR Race = '';
 
-- Standardize race
SELECT
  COUNT(*) AS cnt,
  COUNT(DISTINCT UserID) AS subs,
  CASE
    WHEN Race IN ('other') THEN 'Unkown'
    WHEN Race = ' ' THEN 'Unkown'
    WHEN Race = 'None' THEN 'Unkown'
    WHEN Race ILIKE 'Unkown' THEN 'Unknown'
    ELSE Race
  END AS race
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
GROUP BY CASE
    WHEN Race IN ('other') THEN 'Unkown'
    WHEN Race = ' ' THEN 'Unkown'
    WHEN Race = 'None' THEN 'Unkown'
    WHEN Race ILIKE 'Unkown' THEN 'Unknown'
    ELSE Race
    END;

--Province checks and standardization
-- Distinct provinces  => includes 'None' and empty space (group into one)
SELECT DISTINCT Province
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;
 
-- Standardize province
SELECT DISTINCT
  CASE
    WHEN Province = ' ' THEN 'Uncategorized'
    WHEN Province = 'None' THEN 'Uncategorized'
    ELSE Province
  END AS Province
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;

--Age checks and age buckets
--Inspect the range first (min came back as 0, max as 114 — both need handling), then bucket into groups.
-- Range check
SELECT
  MIN(Age) AS min_age,   -- = 0
  MAX(Age) AS max_age    -- = 114
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;
 
-- Null check
SELECT COUNT(*) AS cnt
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
WHERE Age IS NULL;
 
-- Age groups
WITH cte AS (
  SELECT
    UserID,
    CASE
      WHEN Age = 0 THEN 'Infants'
      WHEN Age BETWEEN 1 AND 3 THEN 'Toddler'
      WHEN Age BETWEEN 4 AND 12 THEN 'Children'
      WHEN Age BETWEEN 13 AND 19 THEN 'Teenager'
      WHEN Age BETWEEN 20 AND 35 THEN 'Youth'
      WHEN Age BETWEEN 36 AND 59 THEN 'Middle Adult'
      ELSE 'Pensioner'
    END AS age_groups
  FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
)
SELECT
age_groups,
COUNT(DISTINCT UserID) AS subs
FROM cte
GROUP BY age_groups;

--Contactability flags (email & social handle)
--Flag who can be reached for campaigns — useful for CVM growth initiatives.
SELECT
  CASE WHEN Email IS NOT NULL AND Email <> '' THEN 1 ELSE 0 END AS email_flag,
  CASE
    WHEN `Social Media Handle` IS NOT NULL
     AND `Social Media Handle` <> ''
     AND `Social Media Handle` NOT IN ('N', 'None')
    THEN 1 ELSE 0
  END AS social_flag
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;

--Combine Cleaned Profiles

SELECT
  UserID,
  TRIM(Name) AS first_name,
  TRIM(Surname) AS last_name,
  LOWER(TRIM(Email)) AS email,
  CASE
    WHEN Gender = ' ' THEN 'Unkown'
    WHEN Gender = 'None' THEN 'Unkown'
    WHEN Gender ILIKE 'Unkown' THEN 'Unknown'
    ELSE Gender
  END AS gender,
  CASE
    WHEN Race IN ('other') THEN 'Unkown'
    WHEN Race = ' ' THEN 'Unkown'
    WHEN Race = 'None' THEN 'Unkown'
    WHEN Race ILIKE 'Unkown' THEN 'Unknown'
    ELSE Race
  END AS race,
  CASE
    WHEN Province = ' ' THEN 'Uncategorized'
    WHEN Province = 'None' THEN 'Uncategorized'
    ELSE Province
  END AS province,
  CASE
    WHEN Age = 0 THEN 'Infants'
    WHEN Age BETWEEN 1 AND 3 THEN 'Toddler'
    WHEN Age BETWEEN 4 AND 12 THEN 'Children'
    WHEN Age BETWEEN 13 AND 19 THEN 'Teenager'
    WHEN Age BETWEEN 20 AND 35 THEN 'Youth'
    WHEN Age BETWEEN 36 AND 59 THEN 'Middle Adult'
    ELSE 'Pensioner'
  END AS age_groups,
  CASE WHEN Email IS NOT NULL AND Email <> '' THEN 1 ELSE 0 END AS email_flag,
  CASE
    WHEN `Social Media Handle` IS NOT NULL
     AND `Social Media Handle` <> ''
     AND `Social Media Handle` NOT IN ('N', 'None')
    THEN 1 ELSE 0
  END AS social_flag
FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles;

--VIEWERSHIP

--Preview and size
-- Preview viewership
SELECT *
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership
LIMIT 10;

-- Rows and active users (the table has two id columns: UserID0 and userid4)
SELECT
  COUNT(*) AS num_rows,
  COUNT(COALESCE(UserID0, userid4)) AS subs,
  COUNT(DISTINCT COALESCE(UserID0, userid4)) AS active_users
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership;

-- Channel verifications

-- See the raw channel values
SELECT DISTINCT Channel2
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership;
 
-- Standardize channel names
SELECT
  CASE
    WHEN Channel2 IN ('SawSee', 'Sawsee') THEN 'SawSee'
    WHEN Channel2 IN ('Supersport Live Events', 'SuperSport Live Events', 'Live on SuperSport')
      THEN 'Live Sport Events'
    ELSE Channel2
  END AS tv_channel
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership;

--Date functions — convert UTC to SA time and extract parts
--All date functions are applied on the viewership data. Convert the UTC timestamp to South Africa time (UTC+2), then extract the day name, month name, day of week, and hour.

SELECT
  -- shift UTC to South Africa time
  RecordDate2 AS record_timestamp_utc,
  RecordDate2 + INTERVAL 2 HOURS AS record_timestamp_sa,
  TO_DATE(RecordDate2 + INTERVAL 2 HOURS) AS view_date_sa,
  DATE_FORMAT(RecordDate2 + INTERVAL 2 HOURS, 'EEEE') AS day_name,
  DATE_FORMAT(RecordDate2 + INTERVAL 2 HOURS, 'MMMM')  AS month_name,
  DAYOFWEEK(RecordDate2 + INTERVAL 2 HOURS) AS day_of_week,
  HOUR(RecordDate2 + INTERVAL 2 HOURS) AS view_hour
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership;

--Duration buckets

SELECT
  HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 AS watch_minutes,
  CASE
    WHEN HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 = 0 THEN 'No watch'
    WHEN HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 < 5 THEN 'Short (<5 min)'
    WHEN HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 < 30 THEN 'Medium (5-30 min)'
    WHEN HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 < 120 THEN 'Long (30-120 min)'
    ELSE 'Very long (2 hrs+)'
  END AS duration_bucket
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership;

--Combined cleaned viewership view
--CREATE OR REPLACE VIEW workspace.bright_tv_case_study.vw_clean_viewership AS
SELECT
  COALESCE(userid4, UserID0) AS user_id,
  UserID0 AS raw_user_id,
  CASE
    WHEN Channel2 IN ('SawSee', 'Sawsee') THEN 'SawSee'
    WHEN Channel2 IN ('Supersport Live Events', 'SuperSport Live Events', 'Live on SuperSport')
      THEN 'Live Events'
    ELSE Channel2
  END AS tv_channel,
  RecordDate2 + INTERVAL 2 HOURS AS record_timestamp_sa,
  TO_DATE(RecordDate2 + INTERVAL 2 HOURS) AS view_date_sa,
  DATE_FORMAT(RecordDate2 + INTERVAL 2 HOURS, 'EEEE')  AS day_name,
  HOUR(RecordDate2 + INTERVAL 2 HOURS) AS view_hour,
  HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 AS watch_minutes
FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership;

 
--Combining user profiles and viewership data
SELECT
  -- User profile fields
  p.UserID,
  p.first_name,
  p.last_name,
  p.email,
  p.gender,
  p.race,
  p.province,
  p.age_groups,
  p.email_flag,
  p.social_flag,
  -- Viewership fields
  v.tv_channel,
  v.record_timestamp_sa,
  v.view_date_sa,
  v.day_name,
  v.view_hour,
  v.watch_minutes,
  -- Duration bucket
  CASE
    WHEN v.watch_minutes = 0 THEN 'No watch'
    WHEN v.watch_minutes < 5 THEN 'Short (<5 min)'
    WHEN v.watch_minutes < 30 THEN 'Medium (5-30 min)'
    WHEN v.watch_minutes < 120 THEN 'Long (30-120 min)'
    ELSE 'Very long (2 hrs+)'
  END AS duration_bucket,
  -- Subscriber activity level
  CASE
    WHEN v.watch_minutes = 0 THEN 'Inactive Subscriber'
    WHEN v.watch_minutes < 5 THEN 'Minimally Active'
    WHEN v.watch_minutes < 30 THEN 'Partially Active'
    WHEN v.watch_minutes >= 30 THEN 'Fully Active'
  END AS activity_level
FROM (
  -- Cleaned profiles
  SELECT
    UserID,
    TRIM(Name) AS first_name,
    TRIM(Surname) AS last_name,
    LOWER(TRIM(Email)) AS email,
    CASE
      WHEN Gender = ' ' THEN 'Unknown'
      WHEN Gender = 'None' THEN 'Unknown'
      WHEN Gender ILIKE 'Unknown' THEN 'Unknown'
      ELSE Gender
    END AS gender,
    CASE
      WHEN Race IN ('other') THEN 'Unknown'
      WHEN Race = ' ' THEN 'Unknown'
      WHEN Race = 'None' THEN 'Unknown'
      WHEN Race ILIKE 'Unknown' THEN 'Unknown'
      ELSE Race
    END AS race,
    CASE
      WHEN Province = ' ' THEN 'Uncategorized'
      WHEN Province = 'None' THEN 'Uncategorized'
      ELSE Province
    END AS province,
    CASE
      WHEN Age = 0 THEN 'Infants'
      WHEN Age BETWEEN 1 AND 3 THEN 'Toddler'
      WHEN Age BETWEEN 4 AND 12 THEN 'Children'
      WHEN Age BETWEEN 13 AND 19 THEN 'Teenager'
      WHEN Age BETWEEN 20 AND 35 THEN 'Youth'
      WHEN Age BETWEEN 36 AND 59 THEN 'Middle Adult'
      ELSE 'Pensioner'
    END AS age_groups,
    CASE WHEN Email IS NOT NULL AND Email <> '' THEN 1 ELSE 0 END AS email_flag,
    CASE
      WHEN `Social Media Handle` IS NOT NULL
       AND `Social Media Handle` <> ''
       AND `Social Media Handle` NOT IN ('N', 'None')
      THEN 1 ELSE 0
    END AS social_flag
  FROM workspace.bright_tv_case_study.bright_tv_dataset_user_profiles
) p
INNER JOIN (
  -- Cleaned viewership
  SELECT
    COALESCE(userid4, UserID0) AS user_id,
    CASE
      WHEN Channel2 IN ('SawSee', 'Sawsee') THEN 'SawSee'
      WHEN Channel2 IN ('Supersport Live Events', 'SuperSport Live Events', 'Live on SuperSport')
        THEN 'Live Sport Events'
      ELSE Channel2
    END AS tv_channel,
    RecordDate2 + INTERVAL 2 HOURS AS record_timestamp_sa,
    TO_DATE(RecordDate2 + INTERVAL 2 HOURS) AS view_date_sa,
    DATE_FORMAT(RecordDate2 + INTERVAL 2 HOURS, 'EEEE') AS day_name,
    HOUR(RecordDate2 + INTERVAL 2 HOURS) AS view_hour,
    HOUR(`Duration 2`) * 60 + MINUTE(`Duration 2`) + SECOND(`Duration 2`) / 60.0 AS watch_minutes
  FROM workspace.bright_tv_case_study.bright_tv_dataset_viewership
) v ON p.UserID = v.user_id;

