
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(c.c_birth_month, 1) AS birth_month,
        COALESCE(c.c_birth_year, 1900) AS birth_year,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
latest_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY d.d_date DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, ws.ws_item_sk
),
customer_sales AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_last_name,
        ch.c_first_name,
        COALESCE(ls.total_sales, 0) AS sales_value,
        COALESCE(ls.total_discount, 0) AS discount_value,
        CASE 
            WHEN ch.rn = 1 THEN 'Primary'
            ELSE 'Secondary'
        END AS customer_type
    FROM customer_hierarchy ch
    LEFT JOIN latest_sales ls ON ch.c_customer_sk = ls.ws_item_sk AND ls.sales_rank = 1
)
SELECT 
    ch.c_last_name,
    ch.c_first_name,
    ch.cd_gender,
    SUM(cs.sales_value) OVER (PARTITION BY ch.customer_type) AS total_sales_per_type,
    AVG(cs.discount_value) OVER (PARTITION BY ch.customer_type) AS avg_discount_per_type,
    COUNT(CASE WHEN ch.birth_month BETWEEN 1 AND 6 THEN 1 END) AS count_birth_first_half,
    COALESCE(NULLIF(AVG(cs.sales_value), 0), 'No Sales') AS avg_sales_value
FROM customer_sales cs
JOIN customer_hierarchy ch ON cs.c_customer_sk = ch.c_customer_sk
WHERE 
    ch.birth_year > 1980 
    AND (ch.cd_credit_rating = 'Good' OR ch.cd_credit_rating IS NULL)
GROUP BY 
    ch.c_last_name,
    ch.c_first_name,
    ch.cd_gender,
    ch.customer_type
ORDER BY 
    total_sales_per_type DESC,
    ch.c_last_name ASC
LIMIT 50;
