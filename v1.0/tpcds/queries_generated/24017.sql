
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date, 1 AS level
    FROM date_dim
    WHERE d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT DATEADD(DAY, -1, d_date), d_date, level + 1
    FROM date_series
    WHERE d_date > '2023-01-01'
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(cd.cd_gender, 'U') ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year < 1990
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
promotion_analysis AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY SUM(ws.ws_net_profit) DESC) AS promo_rank
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name, p.p_promo_id
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(pa.p_promo_name, 'No Promotion') AS promotion,
    cs.total_orders,
    cs.total_profit,
    pa.total_discount,
    pa.order_count,
    ds.d_date,
    CASE 
        WHEN ds.level % 2 = 0 THEN 'Even Day'
        ELSE 'Odd Day'
    END AS day_type
FROM customer_summary cs
FULL OUTER JOIN promotion_analysis pa ON cs.total_orders = pa.order_count
CROSS JOIN date_series ds
WHERE cs.total_profit IS NOT NULL 
    OR pa.total_discount IS NOT NULL
ORDER BY cs.total_profit DESC NULLS LAST, pa.total_discount DESC NULLS LAST;
