-- =============================================================================
-- HR ATTRITION EARLY WARNING SYSTEM - ANALYTICAL QUERIES
-- Dataset: IBM HR Analytics (1,470 employees, 35 features)
-- Purpose: Identify key drivers of employee attrition for intervention
-- =============================================================================

create database hr_attrition;

use hr_attrition;

select * from attrition;

-- ============================================================================
-- QUERY 1: ATTRITION OVERVIEW
-- Purpose: Get baseline metrics — overall attrition rate and organizational
-- structure. 
-- ============================================================================

select count(*) as total_employees,
	sum(case when Attrition='Yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when Attrition='Yes' then 1 else 0 end) * 100/ count(*),2) as attrited_pct,
    count(distinct department) as total_departments,
    round(avg(monthlyincome),2) as avg_salary
from attrition
order by attrited_pct;

-- ============================================================================
-- QUERY 2: ATTRITION BY DEPARTMENT
-- Purpose: Identify which departments have the most critical attrition problems
-- to allocate HR resources. 
-- ============================================================================

select department,
	count(*) as total_employees,
	sum(case when attrition='yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when attrition='yes' then 1 else 0 end) * 100 / count(*),2) as attrited_pct,
    round(avg(monthlyincome),2) as avg_salary,
    round(avg(yearsatcompany),2) as avg_tenure
from attrition
group by department
order by attrited_pct DESC;

-- ============================================================================
-- QUERY 3: ATTRITION BY JOB ROLE
-- Purpose: Find high-risk roles within departments. Some roles (e.g., Sales
-- Executive) are attrition hotspots requiring targeted retention programs.
-- ============================================================================

select jobrole,
	count(*) as total_employees,
    sum(case when attrition='yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when attrition='yes' then 1 else 0 end) * 100 / count(*),2) as attrited_pct,
    round(avg(monthlyincome),2) as avg_salary
from attrition
group by jobrole
order by attrited_pct DESC;

-- ============================================================================
-- QUERY 4: TENURE & RISK ANALYSIS
-- Purpose: Determine critical retention periods. First-year employees are
-- most at risk (often called "onboarding attrition"). This identifies when
-- to intervene most aggressively.
-- ============================================================================

select yearsatcompany,
	count(*) as total_employees,
    sum(case when attrition='yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when attrition='yes' then 1 else 0 end) * 100 / count(*),2) as attrited_pct
from attrition
group by yearsatcompany
order by attrited_pct DESC;

-- ============================================================================
-- QUERY 5: ATTRITION BY WORK-LIFE BALANCE
-- Purpose: Assess if work-life balance satisfaction is a driver of attrition.
-- Employees reporting poor balance (score 1-2) should be flagged for 
-- workload/schedule review.
-- ============================================================================

select 
	worklifebalance,
	count(*) as total_employees,
	sum(case when attrition = 'yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when attrition='yes' then 1 else 0 end) * 100 / count(*),2) as attrited_pct
from attrition
group by worklifebalance
order by attrited_pct DESC;

-- ============================================================================
-- QUERY 6: JOB SATISFACTION & ATTRITION CORRELATION
-- Purpose: Most powerful predictor of attrition. Low satisfaction (1-2) should
-- trigger immediate manager check-in and potential role/team change.
-- ============================================================================

select 
	case 
		when jobsatisfaction in (1,2) then 'Low Satisfaction'
        when jobsatisfaction = 3 then 'Medium Satisfaction'
        when jobsatisfaction = 4 then 'High Satisfaction'
	end as satisfaction_level,
	count(*) as total_employees,
    sum(case when attrition='yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when attrition='yes' then 1 else 0 end) * 100 / count(*),2) as attrited_pct,
    round(avg(yearsatcompany),2) as avg_tenure
from attrition
group by satisfaction_level
order by attrited_pct DESC;

-- ============================================================================
-- QUERY 7: SALARY COMPARISON — ATTRITED VS RETAINED EMPLOYEES
-- Purpose: Quantify salary gap between employees who left vs stayed. Identifies
-- if undercompensation is a driver. 
-- ============================================================================

select attrition,
	   round(avg(monthlyincome),2) as avg_salary,
	   round(avg(yearsatcompany),2) as tenure
from attrition
group by attrition;

-- ============================================================================
-- QUERY 8: OVERTIME IMPACT ON ATTRITION
-- Purpose: Identify if excessive overtime is pushing employees out. High
-- overtime + low satisfaction = immediate burnout risk.
-- ============================================================================

select
	overtime,
	sum(case when attrition='yes' then 1 else 0 end) as attrited_employees,
    round(sum(case when attrition='yes' then 1 else 0 end) * 100 / count(*),2) as attrited_pct
from attrition
group by overtime
order by attrited_pct DESC;
    
-- ============================================================================
-- QUERY 9: HIGH-RISK SEGMENT IDENTIFICATION
-- Purpose: Identify current employees (Attrition = 'No') who show early warning
-- signs of potential departure. Risk levels are defined to guide HR interventions.
-- Risk Scoring Rules:
--   Very High Risk (First Year) = Employees with tenure < 1 year
--   Very High Risk = Employees with tenure < 2, JobSatisfaction <= 2 AND OverTime = 'Yes' 
--   High Risk = Employees with tenure < 2 years, low salary (<3000),
--               and low job satisfaction (<=2)
--   High Risk = Employees with low job satisfaction (<=2), regardless of tenure/salary
--   Low Risk = All other employees
-- ============================================================================

SELECT 
    EmployeeNumber, 
    Age,
    Department,
    JobRole,
    MonthlyIncome,
    YearsAtCompany,
    JobSatisfaction,
    EnvironmentSatisfaction,
    OverTime,
    CASE
        WHEN YearsAtCompany < 2 AND JobSatisfaction <= 2 AND OverTime = 'Yes' THEN 'Very High Risk'
        WHEN YearsAtCompany < 1 THEN 'Very High Risk (First Year)'
        WHEN YearsAtCompany < 2 AND MonthlyIncome < 3000 AND JobSatisfaction <= 2 THEN 'High Risk'
        WHEN JobSatisfaction <= 2 OR OverTime = 'Yes' THEN 'High Risk'        
        ELSE 'Low Risk'
    END AS risk_level
FROM attrition
WHERE Attrition = 'No'
ORDER BY
    CASE
        WHEN YearsAtCompany < 2 AND JobSatisfaction <= 2 AND OverTime = 'Yes' THEN 1
        WHEN YearsAtCompany < 1 THEN 2
        WHEN YearsAtCompany < 2 AND MonthlyIncome < 3000 AND JobSatisfaction <= 2 THEN 3
        WHEN JobSatisfaction <= 2 OR OverTime = 'Yes' THEN 4
        ELSE 5
    END;


    
    



	
