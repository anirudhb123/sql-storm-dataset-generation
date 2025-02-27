
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs.customer_sk, 
        cs.cs_order_number, 
        cs.cs_sales_price, 
        cs.cs_sold_date_sk, 
        ROW_NUMBER() OVER (PARTITION BY cs.customer_sk ORDER BY cs.cs_sales_price DESC) AS sales_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN (SELECT MAX(dd.d_date_sk) FROM date_dim dd WHERE dd.d_year = 2023) - 30 
        AND (SELECT MAX(dd.d_date_sk) FROM date_dim dd WHERE dd.d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year >= 1980
),
top_sales AS (
    SELECT 
        sh.customer_sk, 
        SUM(sh.cs_sales_price) AS total_sales 
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.sales_rank <= 5
    GROUP BY 
        sh.customer_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ts.total_sales, 
    COALESCE(ts.total_sales, 0) AS total_sales_or_zero,
    CASE 
        WHEN ts.total_sales IS NOT NULL THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    customer_info ci
LEFT JOIN 
    top_sales ts ON ci.c_customer_sk = ts.customer_sk
WHERE 
    (ci.gender_rank <= 3 OR ci.cd_marital_status = 'M')
ORDER BY 
    total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
