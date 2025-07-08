
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
recent_orders AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_profit) > 0
),
promotions_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws_order_number) AS promo_order_count,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
),
address_info AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count 
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state
)

SELECT
    ch.c_customer_sk,
    ch.c_first_name || ' ' || ch.c_last_name AS full_name,
    COALESCE(fa.ca_city, 'Unknown') AS city,
    COALESCE(fa.ca_state, 'Unknown') AS state,
    COALESCE(ro.total_profit, 0) AS recent_profit,
    COALESCE(ro.order_count, 0) AS recent_order_count,
    ps.promo_order_count,
    ps.total_sales
FROM customer_hierarchy ch
LEFT JOIN address_info fa ON ch.c_current_addr_sk = fa.ca_address_sk
LEFT JOIN recent_orders ro ON ch.c_customer_sk = ro.ws_bill_customer_sk
LEFT JOIN promotions_summary ps ON ro.ws_bill_customer_sk = ps.promo_order_count
WHERE ch.level = 1
    AND (ro.total_profit IS NULL OR ro.total_profit > 100)
ORDER BY recent_profit DESC, recent_order_count DESC;
