
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 1500
    GROUP BY 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(CASE WHEN cd_gender = 'M' AND cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_male_count,
        SUM(CASE WHEN cd_gender = 'F' AND cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_female_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
    GROUP BY 
        c.c_customer_id, d.d_year
)
SELECT 
    c.c_customer_id,
    r.total_sales,
    r.sales_rank,
    c.year,
    COALESCE(ci.single_male_count, 0) AS single_male_count,
    COALESCE(ci.single_female_count, 0) AS single_female_count
FROM 
    ranked_sales r
LEFT JOIN 
    customer_info ci ON r.ws_item_sk = ci.c_customer_id 
CROSS JOIN (
    SELECT DISTINCT 
        d_year 
    FROM 
        date_dim
) years
JOIN 
    customer c ON c.c_customer_id = r.ws_item_sk
WHERE 
    (r.sales_rank = 1 AND ci.single_male_count IS NULL) OR 
    (r.sales_rank > 5 AND ci.single_female_count IS NOT NULL AND c.c_birth_year > 1990)
ORDER BY 
    r.total_sales DESC, ci.single_female_count DESC 
LIMIT 100
UNION ALL
SELECT 
    'Overall Total' AS c_customer_id,
    SUM(total_sales) AS total_sales,
    NULL AS sales_rank,
    NULL AS year,
    NULL AS single_male_count,
    NULL AS single_female_count
FROM 
    ranked_sales;
