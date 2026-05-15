/*
===========================================================
Diabetes Prediction Data Analysis Project
===========================================================

Project Objective:
Analyze diabetes patient data using SQL to identify
high-risk individuals, compare diabetic and non-diabetic
patients, and perform analytical reporting using advanced
SQL concepts.

Tools Used:
- MySQL Workbench
- SQL
- GitHub

SQL Skills Demonstrated:
- Data Cleaning
- Aggregate Functions
- GROUP BY
- CASE Statements
- Subqueries
- Window Functions
- DENSE_RANK()
- NTILE()
- Analytical Filtering

Dataset:
Pima Indians Diabetes Dataset

===========================================================
*/

CREATE DATABASE diabetes;
USE diabetes;

-- ===========================================================
-- DATA CLEANING
-- ===========================================================

-- Check for null values 

SELECT  
    SUM(CASE WHEN Pregnancies IS NULL THEN 1 ELSE 0 END) AS null_pregnancies,
    SUM(CASE WHEN Glucose IS NULL THEN 1 ELSE 0 END) AS null_glucose,
    SUM(CASE WHEN BloodPressure IS NULL THEN 1 ELSE 0 END) AS null_bp,
    SUM(CASE WHEN BMI IS NULL THEN 1 ELSE 0 END ) AS null_bmi,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN Outcome IS NULL THEN 1 ELSE 0 END) AS null_outcome
FROM diabetes;

-- Check for zero values 

SELECT 
    SUM(CASE WHEN Glucose = 0 THEN 1 ELSE 0 END) AS zero_glucose,
	SUM(CASE WHEN BloodPressure = 0 THEN 1 ELSE 0 END) AS zero_bp,
    SUM(CASE WHEN BMI = 0 THEN 1 ELSE 0 END) AS zero_bmi,
	SUM(CASE WHEN insulin = 0 THEN 1 ELSE 0 END) AS zero_insulin
FROM diabetes;

-- Replacing zeros with null 

SET sql_safe_updates = 0;

UPDATE diabetes 
SET Glucose = NULL
WHERE Glucose = 0;

UPDATE diabetes 
SET BloodPressure = NULL
WHERE BloodPressure = 0;

UPDATE diabetes 
SET BMI = NULL
WHERE BMI = 0;

UPDATE diabetes 
SET insulin = NULL
WHERE insulin = 0;

-- ===========================================================
-- ANALYTICAL QUERIES
-- ===========================================================

-- Q1 Analyze diabetes prevalence across different age groups

SELECT
CASE
    WHEN age BETWEEN 20 AND 30 THEN '20-30'
    WHEN age BETWEEN 31 AND 40 THEN '31-40'
    WHEN age BETWEEN 41 AND 50 THEN '41-50'
    ELSE '51+'
END AS age_group,
COUNT(*) AS diabetic_count FROM diabetes 
WHERE outcome = 1
GROUP BY age_group 
ORDER BY diabetic_count DESC;

-- Insight:
-- Middle-aged and older patients show a higher concentration
-- of diabetes-positive cases compared to younger age groups.
    
-- Q2 Compare average glucose and BMI levels by diabetes outcome 

SELECT
      outcome,
      ROUND(AVG(glucose),2) AS avg_glucose,
      ROUND(AVG(BMI),2) AS avg_bmi
FROM diabetes 
GROUP BY outcome;

-- Insight:
-- Diabetic patients demonstrate significantly higher average
-- glucose and BMI values than non-diabetic patients.

-- Q3 Identify high-risk diabetic patients using multiple health indicators

SELECT
      Pregnancies,
	  Glucose,
      BMI,
      Age
FROM diabetes
WHERE outcome = 1
AND Glucose > (SELECT AVG(Glucose) FROM diabetes)
AND BMI > (SELECT AVG(BMI) FROM diabetes)
AND age > 40 
ORDER BY glucose DESC;

-- Insight:
-- Patients with elevated glucose, high BMI, and increased age
-- represent a high-risk population for diabetes complications.
      
-- Q4 Rank patients based on glucose levels using window functions

SELECT *,
      DENSE_RANK() OVER (ORDER BY glucose DESC) AS glucose_rank
FROM diabetes
WHERE Glucose IS NOT NULL;

-- Insight:
-- Ranking analysis helps identify patients with critically high
-- glucose levels who may require immediate medical attention.

-- Q5 Perform aggregate health metric analysis by patient category

SELECT
    CASE WHEN outcome = 1 THEN 'Diabetic'
         ELSE 'Non-Diabetic' END AS patient_type,
	ROUND(AVG(Glucose),2) AS avg_glucose,
	ROUND(AVG(BMI),2) AS avg_bmi,
	ROUND(AVG(Age),2) AS avg_age,
    ROUND(AVG(BloodPressure),2) AS avg_bp,
	ROUND(AVG(Insulin),2) AS avg_insulin
FROM diabetes 
GROUP BY outcome;

-- Insight:
-- Aggregate metrics indicate noticeable differences in glucose,
-- BMI, insulin, and blood pressure between patient groups.

-- Q6 Classify patients into diabetes risk categories using CASE statements 


SELECT 
	CASE WHEN Glucose < 100 THEN 'Low Risk'
         WHEN Glucose BETWEEN 100 AND 125 THEN 'Pre-Diabetic'
         WHEN Glucose BETWEEN 126 AND 150 THEN 'High-Risk'
         WHEN Glucose > 150 THEN 'Very High Risk'
	END AS risk_category,
    COUNT(*) AS Patients_in_each_category 
FROM diabetes 
WHERE Glucose IS NOT NULL
GROUP BY risk_category 
ORDER BY Patients_in_each_category DESC;

-- Insight:
-- Risk categorization simplifies identification of patients
-- requiring preventive monitoring or medical intervention.

-- Q7 Rank patients within each glucose risk category

SELECT *,
	CASE WHEN Glucose < 100 THEN 'Low Risk'
         WHEN Glucose BETWEEN 100 AND 125 THEN 'Pre-Diabetic'
         WHEN Glucose BETWEEN 126 AND 150 THEN 'High-Risk'
         WHEN Glucose > 150 THEN 'Very High Risk'
	END AS risk_category,
   RANK() OVER (PARTITION BY CASE WHEN Glucose < 100 THEN 'Low Risk'
                                  WHEN Glucose BETWEEN 100 AND 125 THEN 'Pre-Diabetic'
								  WHEN Glucose BETWEEN 126 AND 150 THEN 'High-Risk'
                                  WHEN Glucose > 150 THEN 'Very High Risk'
							 END
                ORDER BY Glucose DESC) AS risk_within_category
FROM diabetes 
WHERE Glucose IS NOT NULL
ORDER BY risk_category, risk_within_category;

-- Insight:
-- Partition-based ranking highlights the highest-risk patients
-- within each glucose risk category.

-- Q8 Calculate average glucose levels across different age groups

SELECT 
    Pregnancies,
    Glucose,
    BMI,
    Age,
    Outcome,
    ROUND(AVG(Glucose) OVER (PARTITION BY CASE WHEN Age BETWEEN 20 AND 30 THEN '20-30'
											   WHEN Age BETWEEN 31 AND 40 THEN '31-40'
                                               WHEN Age BETWEEN 41 AND 50 THEN '41-50'
                                               ELSE '51+'
										  END),2) AS avg_glucose_age_group
FROM diabetes
WHERE Glucose IS NOT NULL;

-- Insight:
-- Average glucose levels tend to increase gradually across
-- higher age groups, indicating elevated diabetes risk.

-- Q9 Analyze diabetes percentage distribution across age groups

SELECT 
    CASE WHEN Age BETWEEN 20 AND 30 THEN '20-30'
         WHEN Age BETWEEN 31 AND 40 THEN '31-40'
         WHEN Age BETWEEN 41 AND 50 THEN '41-50'
         ELSE '51+' END AS age_group,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN Outcome = 1 THEN 1 ELSE 0 END) AS diabetic_patients,
    ROUND(SUM(CASE WHEN Outcome = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS diabetic_percentage
FROM diabetes
GROUP BY age_group
ORDER BY diabetic_percentage DESC;

-- Insight:
-- Certain age groups show a disproportionately higher percentage
-- of diabetic patients compared to others.

-- Q10 Identify diabetic patients with the highest BMI values

SELECT 
    Pregnancies,
    Glucose,
    BMI,
    Age,
    Outcome,
    DENSE_RANK() OVER (ORDER BY BMI DESC) AS bmi_rank
FROM diabetes
WHERE Outcome = 1
AND BMI IS NOT NULL
ORDER BY BMI DESC
LIMIT 10;

-- Insight:
-- Extremely high BMI values are frequently associated with
-- diabetes-positive patients in the dataset.

-- Q11 Identify non-diabetic patients with above-average glucose and BMI levels

SELECT 
    Pregnancies, 
    Glucose, 
    BMI, 
    Age, 
    Outcome
FROM diabetes
WHERE Outcome = 0
AND BMI > (SELECT AVG(BMI) FROM diabetes)
AND Glucose > (SELECT AVG(Glucose) FROM diabetes)
ORDER BY Glucose DESC;

-- Insight:
-- Some non-diabetic patients already exhibit elevated glucose
-- and BMI levels, suggesting potential future diabetes risk.

-- Q12 Segment patients into glucose quartiles using NTILE()

SELECT 
    Pregnancies,
    Glucose,
    BMI,
    Age,
    Outcome,
    NTILE(4) OVER (ORDER BY Glucose DESC) AS glucose_quartile
FROM diabetes
WHERE Glucose IS NOT NULL
ORDER BY glucose_quartile, Glucose DESC;

-- Insight:
-- Quartile segmentation separates patients into percentile-based
-- glucose groups for advanced risk analysis. 

-- Q13 Identify patients with borderline diabetes risk indicators

SELECT 
    Pregnancies,
    Glucose,
    BMI,
    Age,
    Outcome,
    CASE WHEN Outcome = 1 THEN 'Diabetic' 
         ELSE 'Non-Diabetic' END AS patient_type
FROM diabetes
WHERE Glucose BETWEEN 120 AND 140
AND BMI BETWEEN 28 AND 35
ORDER BY Glucose DESC;

-- Insight:
-- Borderline-risk patients may benefit from early lifestyle
-- modifications and regular health monitoring.


/*
===========================================================
PROJECT CONCLUSION
===========================================================

This project demonstrates the use of SQL for healthcare-
oriented data analysis using the Diabetes Prediction Dataset.

Key analytical tasks performed include:
- Data cleaning and preprocessing
- Diabetes risk analysis by age group
- Comparison of diabetic vs non-diabetic patients
- High-risk patient identification
- Aggregate health metric analysis
- Risk categorization using CASE statements
- Window function based rankings and percentile analysis

Advanced SQL concepts such as subqueries, window functions,
DENSE_RANK(), NTILE(), and analytical filtering were used
to generate meaningful patient insights.

===========================================================
*/







