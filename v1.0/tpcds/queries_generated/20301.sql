
WITH recursive_high_income_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, h.hd_income_band_sk
    FROM customer c
    JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    WHERE h.hd_income_band_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, h.hd_income_band_sk
    FROM customer c
    JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    JOIN recursive_high_income_customers rh ON rh.hd_income_band_sk < h.hd_income_band_sk
    WHERE h.hd_income_band_sk IS NOT NULL
),
customer_web_sales AS (
    SELECT ws.ws_ship_customer_sk, SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
),
customer_stores AS (
    SELECT ss.ss_customer_sk, SUM(ss.ss_net_paid) AS total_store_spent
    FROM store_sales ss
    WHERE ss.ss_net_paid IS NOT NULL
    GROUP BY ss.ss_customer_sk
),
recent_returns AS (
    SELECT sr_returning_customer_sk, COUNT(*) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_returning_customer_sk
),
combined_customer_data AS (
    SELECT c.c_customer_sk,
           COALESCE(cw.total_spent, 0) AS online_spending,
           COALESCE(cs.total_store_spent, 0) AS store_spending,
           COALESCE(rr.total_returns, 0) AS return_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(cw.total_spent, 0) + COALESCE(cs.total_store_spent, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN customer_web_sales cw ON c.c_customer_sk = cw.ws_ship_customer_sk
    LEFT JOIN customer_stores cs ON c.c_customer_sk = cs.ss_customer_sk
    LEFT JOIN recent_returns rr ON c.c_customer_sk = rr.sr_returning_customer_sk
    WHERE c.c_birth_year IS NOT NULL AND (c.c_birth_month IS NULL OR c.c_birth_month > 0)
)
SELECT rhc.c_customer_sk, rhc.c_first_name, rhc.c_last_name,
       c.*,
       CASE
           WHEN c.online_spending > c.store_spending THEN 'Online'
           WHEN c.store_spending > c.online_spending THEN 'Store'
           ELSE 'Equal'
       END AS preferred_channel
FROM combined_customer_data c
JOIN recursive_high_income_customers rhc ON c.c_customer_sk = rhc.c_customer_sk
WHERE c.return_count > 0
ORDER BY c.online_spending + c.store_spending DESC
LIMIT 100;
