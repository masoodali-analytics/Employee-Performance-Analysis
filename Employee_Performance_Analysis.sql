/*
Prerequisite: Import the source CSV into SQL Server as dbo.Extended_Employee_Performance_and_Productivity_Data before running the data-cleaning section.
*/

IF DB_ID('EmployeePerformanceDB') IS NULL
BEGIN
    EXEC('CREATE DATABASE EmployeePerformanceDB');
END;
GO

USE EmployeePerformanceDB;
GO

SELECT DB_NAME() AS CurrentDatabase;

CREATE TABLE dbo.EmployeePerformance_Staging
(
    Employee_ID INT,
    Department VARCHAR(50),
    Gender VARCHAR(10),
    Age INT,
    Job_Title VARCHAR(50),
    Hire_Date VARCHAR(50),
    Years_At_Company INT,
    Education_Level VARCHAR(30),
    Performance_Score INT,
    Monthly_Salary DECIMAL(10,2),
    Work_Hours_Per_Week INT,
    Projects_Handled INT,
    Overtime_Hours INT,
    Sick_Days INT,
    Remote_Work_Frequency INT,
    Team_Size INT,
    Training_Hours INT,
    Promotions INT,
    Employee_Satisfaction_Score DECIMAL(4,2),
    Resigned VARCHAR(5)
);


SELECT 
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'EmployeePerformance_Staging';

SELECT
    t.name AS Table_Name,
    SUM(p.rows) AS Row_Count
FROM sys.tables AS t
INNER JOIN sys.partitions AS p
    ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY Row_Count DESC;


SELECT
    t.name AS Table_Name,
    c.column_id AS Column_Number,
    c.name AS Column_Name,
    TYPE_NAME(c.user_type_id) AS Data_Type,
    c.max_length AS Maximum_Length,
    c.precision,
    c.scale
FROM sys.tables AS t
INNER JOIN sys.columns AS c
    ON t.object_id = c.object_id
WHERE t.name LIKE 'Extended_Employee_Performance%'
ORDER BY c.column_id;


INSERT INTO dbo.EmployeePerformance_Staging
(
    Employee_ID,
    Department,
    Gender,
    Age,
    Job_Title,
    Hire_Date,
    Years_At_Company,
    Education_Level,
    Performance_Score,
    Monthly_Salary,
    Work_Hours_Per_Week,
    Projects_Handled,
    Overtime_Hours,
    Sick_Days,
    Remote_Work_Frequency,
    Team_Size,
    Training_Hours,
    Promotions,
    Employee_Satisfaction_Score,
    Resigned
)
SELECT
    TRY_CONVERT(INT, Employee_ID),
    Department,
    Gender,
    TRY_CONVERT(INT, Age),
    Job_Title,
    Hire_Date,
    TRY_CONVERT(INT, Years_At_Company),
    Education_Level,
    TRY_CONVERT(INT, Performance_Score),
    TRY_CONVERT(DECIMAL(10,2), Monthly_Salary),
    TRY_CONVERT(INT, Work_Hours_Per_Week),
    TRY_CONVERT(INT, Projects_Handled),
    TRY_CONVERT(INT, Overtime_Hours),
    TRY_CONVERT(INT, Sick_Days),
    TRY_CONVERT(INT, Remote_Work_Frequency),
    TRY_CONVERT(INT, Team_Size),
    TRY_CONVERT(INT, Training_Hours),
    TRY_CONVERT(INT, Promotions),
    TRY_CONVERT(DECIMAL(4,2), Employee_Satisfaction_Score),
    Resigned
FROM dbo.Extended_Employee_Performance_and_Productivity_Data;


SELECT COUNT(*) AS Staging_Row_Count
FROM dbo.EmployeePerformance_Staging;


SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_ID) AS Unique_Employee_IDs,

    COUNT(*) - COUNT(DISTINCT Employee_ID)
        AS Duplicate_Employee_IDs,

    SUM(
        CASE
            WHEN Employee_ID IS NULL
              OR Age IS NULL
              OR Years_At_Company IS NULL
              OR Performance_Score IS NULL
              OR Monthly_Salary IS NULL
              OR Work_Hours_Per_Week IS NULL
              OR Projects_Handled IS NULL
              OR Overtime_Hours IS NULL
              OR Sick_Days IS NULL
              OR Remote_Work_Frequency IS NULL
              OR Team_Size IS NULL
              OR Training_Hours IS NULL
              OR Promotions IS NULL
              OR Employee_Satisfaction_Score IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Rows_With_Conversion_Errors,

    SUM(
        CASE
            WHEN TRY_CONVERT(DATETIME2(6), Hire_Date) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Hire_Dates,

    SUM(
        CASE
            WHEN Resigned NOT IN ('True', 'False')
                 OR Resigned IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Resigned_Values
FROM dbo.EmployeePerformance_Staging;

CREATE TABLE dbo.EmployeePerformance
(
    Employee_ID INT NOT NULL,
    Department VARCHAR(50) NOT NULL,
    Gender VARCHAR(10) NOT NULL,
    Age INT NOT NULL,
    Job_Title VARCHAR(50) NOT NULL,
    Hire_Date DATETIME2(6) NOT NULL,
    Years_At_Company INT NOT NULL,
    Education_Level VARCHAR(30) NOT NULL,
    Performance_Score INT NOT NULL,
    Monthly_Salary DECIMAL(10,2) NOT NULL,
    Work_Hours_Per_Week INT NOT NULL,
    Projects_Handled INT NOT NULL,
    Overtime_Hours INT NOT NULL,
    Sick_Days INT NOT NULL,
    Remote_Work_Frequency INT NOT NULL,
    Team_Size INT NOT NULL,
    Training_Hours INT NOT NULL,
    Promotions INT NOT NULL,
    Employee_Satisfaction_Score DECIMAL(4,2) NOT NULL,
    Resigned BIT NOT NULL,

    CONSTRAINT PK_EmployeePerformance
        PRIMARY KEY (Employee_ID),

    CONSTRAINT CK_PerformanceScore
        CHECK (Performance_Score BETWEEN 1 AND 5),

    CONSTRAINT CK_SatisfactionScore
        CHECK (Employee_Satisfaction_Score BETWEEN 1 AND 5),

    CONSTRAINT CK_EmployeeAge
        CHECK (Age BETWEEN 18 AND 100),

    CONSTRAINT CK_MonthlySalary
        CHECK (Monthly_Salary >= 0),

    CONSTRAINT CK_RemoteWorkFrequency
        CHECK (Remote_Work_Frequency IN (0, 25, 50, 75, 100))
);

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'EmployeePerformance';

INSERT INTO dbo.EmployeePerformance
(
    Employee_ID,
    Department,
    Gender,
    Age,
    Job_Title,
    Hire_Date,
    Years_At_Company,
    Education_Level,
    Performance_Score,
    Monthly_Salary,
    Work_Hours_Per_Week,
    Projects_Handled,
    Overtime_Hours,
    Sick_Days,
    Remote_Work_Frequency,
    Team_Size,
    Training_Hours,
    Promotions,
    Employee_Satisfaction_Score,
    Resigned
)
SELECT
    Employee_ID,
    Department,
    Gender,
    Age,
    Job_Title,
    CONVERT(DATETIME2(6), Hire_Date),
    Years_At_Company,
    Education_Level,
    Performance_Score,
    Monthly_Salary,
    Work_Hours_Per_Week,
    Projects_Handled,
    Overtime_Hours,
    Sick_Days,
    Remote_Work_Frequency,
    Team_Size,
    Training_Hours,
    Promotions,
    Employee_Satisfaction_Score,
    CASE
        WHEN Resigned = 'True' THEN 1
        WHEN Resigned = 'False' THEN 0
    END
FROM dbo.EmployeePerformance_Staging;


SELECT COUNT(*) AS Final_Row_Count
FROM dbo.EmployeePerformance;

SELECT TOP 10 *
FROM dbo.EmployeePerformance
ORDER BY Employee_ID;

-- Business Question 1:
-- How is the workforce distributed across departments?

SELECT
    Department,
    COUNT(*) AS Employee_Count,
    CAST(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER()
        AS DECIMAL(5,2)
    ) AS Workforce_Percentage
FROM dbo.EmployeePerformance
GROUP BY Department
ORDER BY Employee_Count DESC;

/*
Business Conclusion:
The workforce is distributed relatively evenly across departments.

Marketing has the largest share with 11,216 employees, representing 11.22% of all employee records. Finance follows with 11,200 employees
(11.20%), and Operations has 11,181 employees (11.18%).

No single department dominates the workforce, indicating a balanced departmental structure. This analysis includes all records in the
dataset, including employees marked as resigned.
*/

-- Business Question 2:
-- Which departments have the highest average performance?

SELECT
    Department,
    CAST(AVG(CAST(Performance_Score AS DECIMAL(10,2)))
         AS DECIMAL(4,2)) AS Average_Performance,
    SUM (CASE WHEN Performance_Score >= 4 THEN 1 ELSE 0 END) AS High_Performer_Count,
    CAST (100.0 * SUM (CASE WHEN Performance_Score >= 4 THEN 1 ELSE 0 END) / COUNT (*) AS DECIMAL(5,2)) AS High_Performer_Percentage
FROM dbo.EmployeePerformance
GROUP BY Department
ORDER BY Average_Performance DESC, High_Performer_Percentage DESC;

/*
Business Conclusion:
Engineering has the highest average performance score at 3.02, with 40.29% of its employees classified as high performers.

Operations ranks second with an average score of 3.01 and a 40.27% high-performer rate, followed by IT with an average score
of 3.00 and a 40.09% high-performer rate.

The differences between departments are very small, indicating that employee performance is generally balanced across the company.
*/

-- Business Question 3:
-- Who are the top-performing employees in each department? 

;WITH RankedEmployees AS
(
    SELECT
        Employee_ID,
        Job_Title,
        Projects_Handled,
        Employee_Satisfaction_Score,
        Department,
        Performance_Score,
        ROW_NUMBER() OVER (PARTITION BY Department
    ORDER BY Performance_Score DESC, Projects_Handled DESC, Employee_Satisfaction_Score DESC, Employee_ID ASC ) AS Department_Rank
    FROM dbo.EmployeePerformance
)
SELECT
   Department_Rank,
   Department,
   Employee_ID,
   Job_Title,
   Performance_Score,
   Projects_Handled,
   Employee_Satisfaction_Score
FROM RankedEmployees
WHERE Department_Rank <= 3
ORDER BY Department, Department_Rank;

/*
Business Conclusion:
The query identifies the top three employees in each department, producing 27 employees across the nine departments.

Employees are ranked first by performance score, followed by projects handled and satisfaction score to resolve ties.

For example, the selected Customer Support employees all achieved a performance score of 5 and handled 49 projects. These employees
may be considered for recognition, development opportunities or succession planning. However, the ranking reflects only the
measures available in this dataset.
*/

-- Business Question 4:
-- Which departments have a resignation rate above the company-wide average?

;WITH DepartmentTurnover AS
( 
    SELECT 
       Department, 
       COUNT (*) AS Total_Employees,
       SUM(CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) AS Resigned_Employees,
       100.0 * SUM(CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) / COUNT (*) AS Department_Resignation_Rate
    FROM dbo.EmployeePerformance
    GROUP BY Department
 ),
 CompanyTurnover AS 
 (
SELECT
   100.0 * SUM(CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) / COUNT(*) AS Company_Resignation_Rate
FROM dbo.EmployeePerformance
)
SELECT
   d.Department,
   d.Total_Employees,
   d.Resigned_Employees,
   CAST(d.Department_Resignation_Rate AS DECIMAL(5,2)) AS Department_Resignation_Rate,
   CAST(c.Company_Resignation_Rate AS DECIMAL(5,2)) AS Company_Resignation_Rate,
   CASE WHEN d.Department_Resignation_Rate > c.Company_Resignation_Rate THEN 'Above Company Average' ELSE 'At or Below Company Average'
END AS Turnover_Status
FROM DepartmentTurnover AS d 
CROSS JOIN CompanyTurnover AS C
ORDER BY d.Department_Resignation_Rate DESC, d.Department;

/*
Business Conclusion:
The company-wide resignation rate is 10.01%.

Finance has the highest resignation rate at 10.54%, followed by HR at 10.26% and Legal at 10.22%. Marketing and Operations are
also slightly above the company average.

The differences are relatively small, but Finance shows the largest gap and may deserve further investigation. Factors such
as workload, compensation, management and satisfaction should be examined before deciding why employees are resigning.
*/

-- Business Question 5:
-- How does resignation percentage vary by employee satisfaction level?

;WITH SatisfactionGroups AS
(
    SELECT
        Resigned,
        CASE
            WHEN Employee_Satisfaction_Score < 2 THEN 'Low'
            WHEN Employee_Satisfaction_Score < 4 THEN 'Medium'
            ELSE 'High'
        END AS Satisfaction_Level
    FROM dbo.EmployeePerformance
)
SELECT
    Satisfaction_Level,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) AS Resigned_Employees,
    CAST(
    100.0 * SUM(CASE WHEN Resigned = 1 THEN 1 ELSE 0 END)
    / COUNT(*)
    AS DECIMAL(5,2)
) AS Resignation_Percentage
FROM SatisfactionGroups
GROUP BY Satisfaction_Level
ORDER BY Resignation_Percentage DESC;

/*
Business Conclusion:
Resignation percentages are very similar across all satisfaction levels.

The Medium-satisfaction group has the highest resignation rate at 10.06%, followed by the Low-satisfaction group at 10.02% and the
High-satisfaction group at 9.90%.

The difference between the highest and lowest groups is only 0.16 percentage points. Therefore, employee satisfaction level
does not show a strong relationship with resignation in this dataset. Other factors should also be examined to understand why employees leave.
*/

-- Business Question 6:
-- Which employees have the largest salary shortfalls compared with the average salary for their job title?


;WITH SalaryComparison AS 
(
    SELECT
       Employee_ID,
       Department,
       Job_Title,
       Performance_Score,
       Monthly_Salary,
       AVG(Monthly_Salary) OVER (PARTITION BY Job_Title) AS Job_Title_Average_Salary
       FROM dbo.EmployeePerformance
)
SELECT TOP 20
   Employee_ID,
   Department,
   Job_Title,
   Performance_Score,
   Monthly_Salary,
   CAST (Job_Title_Average_Salary AS DECIMAL(10,2)) AS Job_Title_Average_Salary,
   CAST(Job_Title_Average_Salary - Monthly_Salary AS DECIMAL(10,2)) AS Salary_Gap
FROM SalaryComparison
WHERE Monthly_Salary < Job_Title_Average_Salary
ORDER BY Salary_Gap DESC, Employee_ID ASC;

/*
Business Conclusion:
The query identifies 20 employees with the largest salary shortfalls relative to the average for their job title.

Previously observed results included Engineers earning 6,600.00 compared with a job-title average of 7,799.32,
a monthly gap of 1,199.32.

These differences provide a starting point for compensation review. Below-average pay alone does not establish unfair
pay; experience, tenure, performance and responsibilities should also be considered.

The comparison includes all employee records, including those marked as resigned.
*/

-- Business Question 7:
-- How are training hours associated with employee performance and promotion rates?

;WITH TrainingGroups AS
( 
    SELECT 
       Employee_ID,
       Training_Hours,
       Performance_Score,
       Promotions,
       NTILE (4) OVER (ORDER BY Training_Hours) AS Training_Quartile
    FROM dbo.EmployeePerformance
)
SELECT
   Training_Quartile,
   COUNT(*) AS Total_Employees,
   MIN(Training_Hours) AS Minimum_Training_Hours,
   MAX(Training_Hours) AS Maximum_Training_Hours,
   CAST(AVG(CAST(Performance_Score AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS Average_Performance,
   SUM(CASE WHEN Promotions > 0 THEN 1 ELSE 0 END) AS Promoted_Employees,
   CAST(100.0 * SUM(CASE WHEN Promotions > 0 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL (5,2)) AS Promotion_Percentage 
FROM TrainingGroups
GROUP BY Training_Quartile
ORDER BY Training_Quartile;

/*
Business Conclusion:
Average performance remained nearly identical across all four training quartiles (2.99–3.00). Promotion rates also varied only slightly (66.43%–66.98%).
Therefore, this dataset shows no meaningful association between training hours, performance scores, or promotion rates.
*/

-- Business Question 8:
-- Which employees show multiple workload-risk indicators compared with their department peers?

;WITH EmployeeBenchmarks AS 
(
    SELECT
       Employee_ID,
       Department,
       Job_Title,
       Overtime_Hours,
       Sick_Days,
       Employee_Satisfaction_Score,
       AVG (CAST (Overtime_Hours AS DECIMAL (10,2))) OVER (PARTITION BY Department) AS Department_Average_Overtime,
       AVG (CAST (Sick_Days AS DECIMAL (10,2))) OVER (PARTITION BY Department) AS Department_Average_Sick_Days,
       AVG (CAST (Employee_Satisfaction_Score AS DECIMAL (10,2))) OVER (PARTITION BY Department) AS Department_Average_Satisfaction
    FROM dbo.EmployeePerformance
),
EmployeeRiskScores AS 
(
   SELECT *,
      (CASE WHEN Overtime_Hours > Department_Average_Overtime THEN 1 ELSE 0 END) + 
      (CASE WHEN Sick_Days > Department_Average_Sick_Days THEN 1 ELSE 0 END) + 
      (CASE WHEN Employee_Satisfaction_Score < Department_Average_Satisfaction THEN 1 ELSE 0 END) AS Risk_Score
   FROM EmployeeBenchmarks
)
SELECT TOP (20)
    Employee_ID,
    Department,
    Job_Title,
    Overtime_Hours,
    CAST(Department_Average_Overtime AS DECIMAL(5,2)) AS Department_Average_Overtime,
    Sick_Days,
    CAST(Department_Average_Sick_Days AS DECIMAL(5,2)) AS Department_Average_Sick_Days,
    Employee_Satisfaction_Score,
    CAST(Department_Average_Satisfaction AS DECIMAL(5,2)) AS Department_Average_Satisfaction,
    Risk_Score
FROM EmployeeRiskScores
WHERE Risk_Score >= 2
ORDER BY Risk_Score DESC, Employee_ID;

/*
Business Conclusion:
The query identifies 20 employees with the highest workload-risk priority who meet at least two of the three screening conditions:
above-average overtime, above-average sick days or below-average satisfaction within their department.

Employees with a risk score of 3 meet all three conditions and are listed first. These indicators may support further workload review,
but they do not prove employee burnout.
*/

-- Business Question 9:
-- Do male and female employees working in the same department and job title have different average salaries?

;WITH SalaryByGroup AS 
(
SELECT
    Department,
    Job_Title,
    SUM (CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS Male_Employees, 
    SUM (CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS Female_Employees,
    CAST (AVG(CASE WHEN Gender = 'Male' THEN CAST (Monthly_Salary AS DECIMAL (10,2)) END) AS DECIMAL (10,2)) AS Male_Average_Salary,
    CAST (AVG(CASE WHEN Gender = 'Female' THEN CAST (Monthly_Salary AS DECIMAL (10,2)) END) AS DECIMAL (10,2)) AS Female_Average_Salary
FROM dbo.EmployeePerformance
GROUP BY Department, Job_Title
HAVING SUM (CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) >= 30
       AND
       SUM (CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) >= 30
)
SELECT *,
    CAST (Male_Average_Salary - Female_Average_Salary AS DECIMAL (10,2)) AS Male_Minus_Female_Salary,
    CAST (100.0 * (Male_Average_Salary - Female_Average_Salary) / NULLIF (Male_Average_Salary,0) AS DECIMAL (5,2)) AS Male_Minus_Female_Percentage
FROM SalaryByGroup
ORDER BY ABS (Male_Average_Salary - Female_Average_Salary) DESC;

/*
Business Conclusion:
The largest absolute average monthly salary difference was $112.94 for Engineering Managers. Female employees averaged $7,875.59,
compared with $7,762.65 for male employees, producing a signed male-minus-female difference of -$112.94, or -1.45%.

The observed differences were generally small. These results describe salary patterns but do not establish gender-based pay discrimination.
Experience, education, tenure and responsibilities would require further analysis.
*/

-- Business Question 10:
-- Which employee-tenure groups have the highest resignation rates?

;WITH TenureGroups AS 
(
     SELECT
         Employee_ID,
         Years_At_Company,
         Resigned,
         CASE 
             WHEN Years_At_Company <= 1 THEN 'New' 
             WHEN Years_At_Company <= 4 THEN 'Developing' 
             WHEN Years_At_Company <= 7 THEN 'Experienced' ELSE 'Long-Tenured'
         END AS Tenure_Group 
     FROM dbo.EmployeePerformance
)
SELECT 
   Tenure_Group,
   COUNT (*) AS Employee_Count,
   SUM (CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) AS Resigned_Employees,
   CAST (100.0 * SUM (CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) / COUNT (*) AS DECIMAL (5,2)) AS Resignation_Percentage
FROM TenureGroups
GROUP BY Tenure_Group
ORDER BY Resignation_Percentage DESC;

/*
Business Conclusion:
Long-tenured employees had the highest resignation rate at 10.19%, followed closely by new employees at 10.11%.

The resignation rates across tenure groups were very similar, suggesting that employee tenure alone is not a strong indicator of resignation in
this dataset. Other factors should be considered alongside tenure.
*/

-- Business Question 11:
-- How does remote-work frequency relate to employee performance, satisfaction and resignation rates?

SELECT
    Remote_Work_Frequency,
    COUNT (*) AS Employee_Count,
    CAST (AVG (CAST (Performance_Score AS DECIMAL (10,2))) AS DECIMAL (10,2)) AS Average_Performance,
    CAST (AVG (CAST (Employee_Satisfaction_Score AS DECIMAL (10,2))) AS DECIMAL(10,2)) AS Average_Satisfaction,
    SUM (CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) AS Resigned_Employees,
    CAST (100.0 * SUM (CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) / COUNT (*) AS DECIMAL (10,2)) AS Resigned_Percentage
FROM dbo.EmployeePerformance
GROUP BY Remote_Work_Frequency
ORDER BY Remote_Work_Frequency;

/*
Business Conclusion:
Average performance (2.98–3.01) and satisfaction (2.99–3.01) were similar across remote-work frequency groups.

Resignation percentages ranged from 9.48% at frequency 0 to 10.28% at frequency 75, with no consistently increasing
or decreasing pattern.

These descriptive results do not establish that remote work causes changes in performance, satisfaction or resignation.
*/

-- Business Question 12:
-- Which departments account for the largest share of total monthly salary costs, and what is their cumulative share?

;WITH DepartmentSalary AS 
(
SELECT
    Department,
    COUNT (*) AS Employee_Count,
    SUM (Monthly_Salary) AS Total_Monthly_Salary,
    CAST (AVG (CAST (Monthly_Salary AS DECIMAL (10,2))) AS DECIMAL (10,2)) AS Average_Monthly_Salary
FROM dbo.EmployeePerformance
GROUP BY Department
)
SELECT
    Department,
    Employee_Count,
    Total_Monthly_Salary,
    Average_Monthly_Salary,
    SUM (Total_Monthly_Salary) OVER (ORDER BY Total_Monthly_Salary DESC, Department 
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_Salary,
    CAST (100.0 * Total_Monthly_Salary / SUM (Total_Monthly_Salary) OVER () AS DECIMAL (5,2)) AS Salary_Share_Percentage,
    CAST (100.0 * SUM (Total_Monthly_Salary) OVER (ORDER BY Total_Monthly_Salary DESC, Department
                                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM (Total_Monthly_Salary) OVER ()
                                                   AS DECIMAL(5,2)) AS Cumulative_Share_Percentage

FROM DepartmentSalary
ORDER BY Total_Monthly_Salary DESC, Department;

/*
Business Conclusion:
Total monthly salaries recorded in the dataset were 640,321,100. Operations contributed the largest share at 11.20%.
The three largest departments by salary total—Operations, Finance and Marketing—together accounted for 33.56%.

Department shares ranged from 10.96% to 11.20%, indicating that salary totals were spread evenly across departments.

This calculation includes all employee records, including those marked as resigned; it does not represent current payroll.
*/

-- Business Question 13:
-- How does the median monthly salary compare with the average monthly salary for each job title?

;WITH SalaryStatistics AS 
(
SELECT 
    Job_Title,
    Monthly_Salary,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Monthly_Salary) OVER (PARTITION BY Job_Title) AS Median_Salary
FROM dbo.EmployeePerformance
)
SELECT
    Job_Title,
    COUNT (*) AS Employee_Count,
    CAST (AVG (Monthly_Salary) AS DECIMAL (10,2)) AS Average_Monthly_Salary,
    CAST (MAX (Median_Salary) AS DECIMAL (10,2)) AS Median_Monthly_Salary
FROM SalaryStatistics
GROUP BY Job_Title
ORDER BY Average_Monthly_Salary DESC;

/*
Business Conclusion:
Average and median monthly salaries were very close across all seven job titles. The largest absolute difference was 9.86 for Developers.

Both measures give a similar picture of typical salary within each job title. However, their similarity alone does not prove that salary outliers are absent.
*/

-- Business Question 14:
-- How have annual hiring counts changed compared with the previous year?

;WITH AnnualHiring AS
(
SELECT
    YEAR (Hire_Date) AS Hire_Year,
    COUNT (*) AS Employees_Hired
FROM dbo.EmployeePerformance
GROUP BY YEAR (Hire_Date) 
),
HiringComparison AS 
(
SELECT
    Hire_Year,
    Employees_Hired,
    LAG (Employees_Hired) OVER (ORDER BY Hire_Year) AS Previous_Year_Hires
FROM AnnualHiring
)
SELECT
    Hire_Year,
    Employees_Hired,
    Previous_Year_Hires,
    Employees_Hired - Previous_Year_Hires AS Hiring_Change,
    CAST (100.0 * (Employees_Hired - Previous_Year_Hires) / NULLIF (Previous_Year_Hires,0) AS DECIMAL (10,2)) AS Hiring_Change_Percentage
FROM HiringComparison
ORDER BY Hire_Year;

SELECT
    MIN(Hire_Date) AS Earliest_Hire_Date,
    MAX(Hire_Date) AS Latest_Hire_Date
FROM dbo.EmployeePerformance;

/*
Business Conclusion:
Recorded hiring counts were relatively stable from 2015 through 2023. Year-over-year changes from 2016 through
2023 ranged from -1.70% to +1.61%.

Hire dates span September 7, 2014, to September 3, 2024. The boundary years contain partial-year records, so the
2015 increase and 2024 decrease are not comparable full-year changes.

These results describe employee records in this dataset, not necessarily the company's complete hiring history.
*/

-- Business Question 15:
-- Within each department, how do resignation rates differ between high-performing employees and other employees?

;WITH PerformanceGroups AS 
(
SELECT
    Employee_ID,
    Department,
    Performance_Score,
    Resigned,
    CASE WHEN Performance_Score >= 4 THEN 'High Performer' ELSE 'Other' END AS  Performance_Group
FROM dbo.EmployeePerformance
)
SELECT
    Department,
    Performance_Group,
    COUNT (*) AS Total_Employees,
    SUM (CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) AS Resigned_Employees,
    CAST (100.0 * SUM (CASE WHEN Resigned = 1 THEN 1 ELSE 0 END) / COUNT (*) AS DECIMAL (5,2)) AS Resignation_Percentage
FROM PerformanceGroups
GROUP BY Department, Performance_Group
ORDER BY Department, Performance_Group;

/*
Business Conclusion:
High performers had higher resignation percentages in Finance, HR, IT and Sales, and lower percentages in the
other five departments.

All within-department differences were below one percentage point. Marketing had the largest displayed gap: 9.54% for
high performers versus 10.34% for other employees, a difference of 0.80 percentage points.

There was no consistent direction across departments. These descriptive comparisons do not establish that
performance causes resignation or that the differences are statistically significant.
*/

