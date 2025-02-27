
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    
    UNION ALL

    SELECT ca_address_sk, ca.city, ca_state, ca_country, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_state = ah.ca_state
    WHERE ah.level < 3
),
customer_ranked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk,
        RANK() OVER (PARTITION BY d.cd_gender ORDER BY d.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
top_customers AS (
    SELECT *,
        CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            WHEN cd_income_band_sk = 1 THEN 'Low'
            WHEN cd_income_band_sk = 2 THEN 'Medium'
            WHEN cd_income_band_sk = 3 THEN 'High'
            ELSE 'Undefined'
        END AS income_band
    FROM customer_ranked
    WHERE purchase_rank <= 5
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.income_band,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.avg_order_value, 0) AS avg_order_value,
    ah.ca_city,
    ah.ca_country
FROM top_customers tc
LEFT JOIN sales_summary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
JOIN address_hierarchy ah ON tc.c_current_addr_sk = ah.ca_address_sk
WHERE total_profit > 1000 OR total_orders > 10
ORDER BY tc.c_last_name ASC, tc.c_first_name ASC;
