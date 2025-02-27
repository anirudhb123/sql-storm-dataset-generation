
WITH RECURSIVE address_hierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_name, 
        ca_city, 
        ca_state,
        1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_name, 
        ca_city, 
        ca_state,
        level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_zip = (SELECT ca_zip FROM customer_address WHERE ca_address_sk = ah.ca_address_sk + 1)
    WHERE ca.ca_zip IS NOT NULL
),

customer_stats AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(COALESCE(cd.cd_credit_rating, '0')) AS avg_credit_rating,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),

sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
)

SELECT 
    ah.ca_city,
    ah.ca_state,
    COALESCE(cs.max_purchase_estimate, 0) AS max_est_purchase,
    ss.total_quantity,
    ss.total_net_sales,
    CASE 
        WHEN ss.rank = 1 THEN 'Top Selling Date'
        ELSE 'Other'
    END AS ranking
FROM address_hierarchy ah
FULL OUTER JOIN customer_stats cs ON cs.c_customer_sk IN (SELECT c_current_addr_sk FROM customer WHERE c_current_cdemo_sk = cs.c_customer_sk)
LEFT JOIN sales_summary ss ON ss.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date >= CURRENT_DATE - INTERVAL '30 days')
WHERE ah.ca_state IS NOT NULL
ORDER BY ah.ca_city, max_est_purchase DESC
LIMIT 100
UNION ALL
SELECT 
    'Total' AS ca_city, 
    ' ' AS ca_state,
    SUM(cs.max_purchase_estimate), 
    SUM(ss.total_quantity), 
    SUM(ss.total_net_sales),
    'Aggregate' AS ranking
FROM customer_stats cs, sales_summary ss;
