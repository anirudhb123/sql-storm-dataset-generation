
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk,
        0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
top_customers AS (
    SELECT 
        ch.c_customer_sk, 
        CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
        cd.cd_marital_status,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(ws.net_profit) DESC) AS marital_rank
    FROM customer_hierarchy ch
    JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(ws_inner.ws_sold_date_sk) 
        FROM web_sales ws_inner 
        WHERE ws_inner.ws_bill_customer_sk = ch.c_customer_sk
    )
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, cd.cd_marital_status, cd.cd_gender
),
income_bounds AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM income_band ib
    WHERE ib.ib_lower_bound <= (
        SELECT MAX(cd.cd_purchase_estimate)
        FROM customer_demographics cd
    )
)
SELECT 
    tc.full_name,
    tc.cd_marital_status,
    tc.cd_gender,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    CASE 
        WHEN tc.marital_rank <= 5 THEN 'Top 5' 
        ELSE 'Other'
    END AS rank_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM top_customers tc
LEFT JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN income_bounds ib ON tc.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE tc.cd_gender = 'F'
GROUP BY tc.full_name, tc.cd_marital_status, tc.cd_gender, tc.marital_rank, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_profit DESC, total_orders DESC, full_name ASC;
