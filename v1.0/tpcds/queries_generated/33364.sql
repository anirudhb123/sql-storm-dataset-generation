
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS ranking
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),

address_details AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

customer_info AS (
    SELECT 
        ad.customer_id,
        sa.total_profit,
        sa.order_count,
        CASE 
            WHEN sa.order_count > 5 THEN 'Frequent'
            WHEN sa.order_count BETWEEN 1 AND 5 THEN 'Occasional'
            ELSE 'Rare'
        END AS customer_type
    FROM 
        sales_totals sa
    JOIN 
        address_details ad ON sa.customer_id = ad.c_customer_id
)

SELECT 
    ci.customer_id,
    ci.total_profit,
    ci.order_count,
    ci.customer_type,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM 
    customer_info ci
LEFT JOIN 
    address_details ad ON ci.customer_id = ad.customer_id
WHERE 
    ci.total_profit IS NOT NULL
ORDER BY 
    ci.total_profit DESC
LIMIT 10

UNION ALL

SELECT 
    ad.customer_id,
    0 AS total_profit,
    0 AS order_count,
    'Inactive' AS customer_type,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM 
    address_details ad
WHERE 
    ad.customer_id NOT IN (SELECT customer_id FROM customer_info)
ORDER BY 
    total_profit DESC;
