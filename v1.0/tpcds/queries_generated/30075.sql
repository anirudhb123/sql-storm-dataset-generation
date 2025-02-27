
WITH RECURSIVE sales_per_month AS (
    SELECT 
        d_year, 
        d_month_seq, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, 
        d_month_seq
    UNION ALL
    SELECT 
        d_year, 
        d_month_seq, 
        SUM(cs_ext_sales_price) 
    FROM 
        catalog_sales 
    JOIN 
        date_dim ON cs_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, 
        d_month_seq
),
monthly_sales AS (
    SELECT 
        d_year, 
        d_month_seq, 
        total_sales
    FROM 
        sales_per_month
),
customer_demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        cd_purchase_estimate 
    FROM 
        customer_demographics 
    WHERE 
        cd_purchase_estimate > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_preferred_cust_flag, 
        cd.*
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        cs_month.d_year, 
        cs_month.d_month_seq, 
        SUM(ws.ws_ext_sales_price) as web_sales, 
        SUM(cs.cs_ext_sales_price) as catalog_sales
    FROM 
        monthly_sales cs_month
    LEFT JOIN 
        web_sales ws ON cs_month.d_year = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON cs_month.d_year = cs.cs_sold_date_sk
    GROUP BY 
        cs_month.d_year, 
        cs_month.d_month_seq
)
SELECT 
    ci.c_customer_id, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    COALESCE(ss.web_sales, 0) AS total_web_sales, 
    COALESCE(ss.catalog_sales, 0) AS total_catalog_sales,
    (COALESCE(ss.web_sales, 0) + COALESCE(ss.catalog_sales, 0)) AS total_sales
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.cd_demo_sk = ss.d_year AND ci.cd_demo_sk = ss.d_month_seq
WHERE 
    (ci.cd_gender = 'F' AND ci.cd_marital_status IS NULL)
    OR (ci.cd_gender = 'M' AND ci.cd_education_status LIKE '%Graduate%')
ORDER BY 
    total_sales DESC
LIMIT 50;
