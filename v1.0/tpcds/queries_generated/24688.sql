
WITH recent_customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
seasonal_promotion AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_start_date_sk <= 20230101 AND p.p_end_date_sk >= 20230101
    GROUP BY p.p_promo_id, p.p_promo_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_sales,
        cd.cd_marital_status,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender_desc
    FROM recent_customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.total_sales > 500
),
result AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_sales,
        hvc.cd_marital_status,
        hvc.gender_desc,
        sp.promo_order_count
    FROM high_value_customers hvc
    LEFT JOIN seasonal_promotion sp ON hvc.total_sales > 1000
)
SELECT 
    r.c_customer_sk,
    r.total_sales,
    r.cd_marital_status,
    r.gender_desc,
    COALESCE(r.promo_order_count, 0) AS promo_order_count,
    CASE 
        WHEN r.promo_order_count IS NULL THEN 'No Promotions Used'
        ELSE 'Promotions Used'
    END AS promo_status
FROM result r
ORDER BY r.total_sales DESC
LIMIT 50;
