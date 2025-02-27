
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_birth_year > 1980
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY ws.ws_item_sk
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        SUM(cs.cs_quantity) AS promo_quantity,
        SUM(cs.cs_net_profit) AS promo_profit
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE p.p_start_date_sk <= 2450500 AND p.p_end_date_sk >= 2450000
    GROUP BY p.p_promo_id
),
combined_data AS (
    SELECT 
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(ps.promo_quantity, 0) AS promo_quantity,
        COALESCE(ps.promo_profit, 0) AS promo_profit
    FROM customer_hierarchy ch
    LEFT JOIN sales_data sd ON ch.c_customer_sk = sd.ws_item_sk
    LEFT JOIN promotion_summary ps ON sd.ws_item_sk = ps.promo_quantity
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    SUM(cd.total_sales) OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY d.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    STRING_AGG(DISTINCT ps.p_promo_id) AS promo_ids
FROM combined_data cd
JOIN date_dim d ON d.d_date_sk BETWEEN 2450000 AND 2450500
LEFT JOIN customer c ON c.c_customer_sk = cd.c_customer_sk
GROUP BY c.c_first_name, c.c_last_name, d.d_year
HAVING SUM(cd.total_sales) > 1000
ORDER BY cumulative_sales DESC;
