
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND
                                (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.sold_date_sk, ss.store_sk
    
    UNION ALL
    
    SELECT 
        s.sold_date_sk,
        s.store_sk,
        SUM(s.ext_sales_price) AS total_sales,
        c.level + 1 AS level
    FROM 
        store_sales s
    JOIN 
        sales_cte c ON s.store_sk = c.store_sk AND s.sold_date_sk < c.sold_date_sk
    GROUP BY 
        s.sold_date_sk, s.store_sk, c.level
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
result AS (
    SELECT 
        s.store_sk,
        s.total_sales,
        COALESCE(cd.c_first_name, 'Unknown') AS first_name,
        COALESCE(cd.c_last_name, 'Unknown') AS last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(s.total_sales) OVER(PARTITION BY cd.cd_gender) AS gender_total_sales
    FROM 
        sales_cte s
    LEFT JOIN 
        customer_details cd ON s.store_sk = cd.c_customer_sk
    WHERE 
        cd.purchase_rank <= 10
)
SELECT 
    r.store_sk,
    SUM(r.total_sales) AS overall_sales,
    AVG(r.gender_total_sales) AS avg_sales_by_gender,
    COUNT(DISTINCT r.first_name) AS distinct_customer_count,
    COUNT(r.first_name) FILTER (WHERE r.cd_gender = 'M') AS male_customers,
    COUNT(r.first_name) FILTER (WHERE r.cd_gender = 'F') AS female_customers
FROM 
    result r
GROUP BY 
    r.store_sk
ORDER BY 
    overall_sales DESC
LIMIT 10;
