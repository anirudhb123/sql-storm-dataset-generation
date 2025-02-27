
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_address_id, a.ca_city, a.ca_state, ah.level + 1
    FROM customer_address a
    INNER JOIN address_hierarchy ah ON a.ca_state = ah.ca_state AND a.ca_city <> ah.ca_city
    WHERE ah.level < 3
),
active_customers AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        COUNT(DISTINCT s.s_store_sk) AS store_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s ON s.s_store_sk = c.c_current_addr_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
)
SELECT 
    ah.ca_address_id,
    ac.gender,
    d.d_date,
    ds.total_net_profit,
    ds.avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(CASE WHEN ws.ws_net_paid > 0 THEN ws.ws_net_paid ELSE NULL END) AS max_paid,
    COUNT(ws.ws_item_sk) OVER (PARTITION BY ah.ca_address_id) AS item_count,
    COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount,
    COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_demo_sk END) AS married_customers
FROM address_hierarchy ah
JOIN active_customers ac ON ac.store_count > 0
LEFT JOIN daily_sales ds ON ds.d_date = CURRENT_DATE - INTERVAL '7 days'
LEFT JOIN web_sales ws ON ws.ws_bill_addr_sk = ah.ca_address_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = ac.c_customer_sk
WHERE ds.total_net_profit IS NOT NULL
  AND (ac.store_count > 1 OR (ac.store_count = 1 AND ac.gender = 'Female'))
GROUP BY ah.ca_address_id, ac.gender, d.d_date, ds.total_net_profit, ds.avg_sales_price
HAVING COUNT(ws.ws_order_number) > 5
ORDER BY ds.total_net_profit DESC NULLS LAST;
