CREATE DATABASE diabetes;
use diabetes;

select * from diabetes;

-- Check for null values 

select 
    sum(case when Pregnancies is null then 1 else 0 end) as null_pregnancies,
    sum(case when Glucose is null then 1 else 0 end) as null_glucose,
    sum(case when BloodPressure is null then 1 else 0 end) as null_bp,
    sum(case when BMI is null then 1 else 0 end ) as null_bmi,
    sum(case when Age is null then 1 else 0 end) as null_age,
    sum(case when Outcome is null then 1 else 0 end) as null_outcome
from diabetes;

-- Check for zero values 

select
    sum(case when Glucose = 0 then 1 else 0 end) as zero_glucose,
    sum(case when BloodPressure = 0 then 1 else 0 end) as zero_bp,
    sum(case when BMI = 0 then 1 else 0 end) as zero_bmi,
    sum(case when insulin = 0 then 1 else 0 end) as zero_insulin
from diabetes;

-- Replacing zeros with null 

set sql_safe_updates = 0;

update diabetes 
set Glucose = null 
where Glucose = 0;

update diabetes 
set BloodPressure = null
where BloodPressure = 0;

update diabetes 
set BMI = null 
where BMI = 0;

update diabetes 
set insulin = null 
where insulin = 0;

-- Q1 Finding age groups with highest diabetes risk

select 
case 
    when age between 20 and 30 then '20-30'
    when age between 31 and 40 then '31-40'
    when age between 41 and 50 then '41-50'
    else '51+'
end as age_group,
count(*) as diabetic_count from diabetes 
where outcome = 1
group by age_group 
order by diabetic_count desc;
    
-- Q2 Comparing average Glucose and BMI of diabetic vs non-diabetic patients 

select 
      outcome,
      round(avg(glucose),2) as avg_glucose,
      round(avg(BMI),2) as avg_bmi
from diabetes 
group by outcome;
























