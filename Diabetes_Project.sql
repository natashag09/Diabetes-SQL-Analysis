CREATE DATABASE diabetes;
USE diabetes;

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

-- Q1 Finding age groups with highest diabetes risk

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
    
-- Q2 Comparing average Glucose and BMI of diabetic vs non-diabetic patients 

SELECT
      outcome,
      ROUND(AVG(glucose),2) AS avg_glucose,
      ROUND(AVG(BMI),2) AS avg_bmi
FROM diabetes 
GROUP BY outcome;

-- Q3 Identifying high risk patients using multiple conditions

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
      
-- Q4 Ranking patients by glucose or BMI levels 

SELECT *,
      DENSE_RANK() OVER (ORDER BY glucose DESC) AS glucose_rank
FROM diabetes;

-- Q5 Correlation-style analysis using aggregates 

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

-- Q6 Creating risk categories with case when 

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

-- Q7 Window funtion based rankings and percentiles 

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

-- Q8 Calculate average glucose level within each age group

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

-- Q9 Find percentage of diabetic patients in each age group

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

-- Q10 Find top 10 patients with highest BMI who are diabetic

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

-- Q11 Find patients with above average BMI and glucose but no diabetes

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

-- Q12 Find patients in top 25th percentile for glucose using NTILE

SELECT 
    Pregnancies,
    Glucose,
    BMI,
    Age,
    Outcome,
    NTILE(4) OVER (ORDER BY Glucose DESC) AS glucose_quartile
FROM diabetes
WHERE Glucose IS NOT NULL
ORDER BY Glucose DESC;

-- Q13 Find patients who are at borderline risk 
-- (glucose between 120-140 and BMI between 28-35)

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











