
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk, ws.web_site_sk
),
customer_engagement AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS engagement_profit,
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        ce.c_customer_sk,
        ce.order_count,
        ce.engagement_profit,
        CASE 
            WHEN ce.order_count > 10 AND ce.engagement_profit > 500 THEN 'VIP'
            WHEN ce.order_count <= 10 AND ce.engagement_profit > 200 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_segment
    FROM customer_engagement ce
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT hvc.c_customer_sk) AS customer_count,
    AVG(ss.total_net_profit) AS avg_net_profit_per_item
FROM customer_address ca
LEFT JOIN high_value_customers hvc ON hvc.c_customer_sk IN (
    SELECT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_current_addr_sk = ca.ca_address_sk
)
JOIN sales_summary ss ON ss.ws_item_sk IN (
    SELECT i.i_item_sk 
    FROM item i 
    WHERE i.i_brand = 'BrandX'
)
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT hvc.c_customer_sk) > 5 AND AVG(ss.total_net_profit) > 100
ORDER BY ca.ca_city, ca.ca_state;
