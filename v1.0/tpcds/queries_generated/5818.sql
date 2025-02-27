
WITH year_sales AS (
    SELECT 
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
age_group AS (
    SELECT 
        CASE 
            WHEN YEAR(CURRENT_DATE) - c.c_birth_year BETWEEN 0 AND 17 THEN '0-17'
            WHEN YEAR(CURRENT_DATE) - c.c_birth_year BETWEEN 18 AND 24 THEN '18-24'
            WHEN YEAR(CURRENT_DATE) - c.c_birth_year BETWEEN 25 AND 34 THEN '25-34'
            WHEN YEAR(CURRENT_DATE) - c.c_birth_year BETWEEN 35 AND 44 THEN '35-44'
            WHEN YEAR(CURRENT_DATE) - c.c_birth_year BETWEEN 45 AND 54 THEN '45-54'
            WHEN YEAR(CURRENT_DATE) - c.c_birth_year BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+' 
        END AS age_range,
        c.c_customer_sk
    FROM 
        customer c
),
sales_summary AS (
    SELECT 
        ag.age_range,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sales
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.ws_bill_customer_sk = cd.cd_demo_sk
    JOIN 
        age_group ag ON c.c_customer_sk = ag.c_customer_sk
    GROUP BY 
        ag.age_range, cd.cd_gender
)
SELECT 
    s.year,
    ss.age_range,
    ss.cd_gender,
    ss.num_customers,
    ss.total_sales,
    ss.avg_sales
FROM 
    year_sales s
JOIN 
    sales_summary ss ON s.year = YEAR(CURRENT_DATE)
ORDER BY 
    s.year, ss.age_range, ss.cd_gender;
