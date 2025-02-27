
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_marital_status, 'M') AS marital_status,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        0 AS level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.marital_status,
        ch.gender,
        ch.credit_rating,
        ch.purchase_estimate + COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        level + 1
    FROM customer_hierarchy ch
    LEFT JOIN customer c ON ch.c_customer_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ch.level < 5
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
    GROUP BY ws_item_sk
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.marital_status,
    h.gender,
    h.purchase_estimate,
    COALESCE(ts.total_spent, 0) AS total_spent,
    DENSE_RANK() OVER (PARTITION BY h.gender ORDER BY COALESCE(ts.total_spent, 0) DESC) AS spending_rank,
    CASE 
        WHEN h.purchase_estimate > 1000 THEN 'High Value'
        WHEN h.purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    COALESCE((SELECT SUM(total_profit) FROM item_sales WHERE ws_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = h.c_customer_sk
    )), 0) AS total_item_profit
FROM customer_hierarchy h
LEFT JOIN total_sales ts ON h.c_customer_sk = ts.customer_sk
ORDER BY h.c_customer_sk;
