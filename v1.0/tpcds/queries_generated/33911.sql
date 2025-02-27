
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        NULL AS parent_customer_sk,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT 
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.c_customer_sk AS parent_customer_sk,
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        sales_hierarchy sh ON ws.ws_ship_customer_sk = sh.c_customer_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk
),
customer_ranked AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        customer_stats cs
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    cr.total_orders,
    cr.total_profit,
    cr.rank,
    COALESCE(a.ca_city, 'Unknown') AS shipping_city, 
    CASE 
        WHEN a.ca_state IS NULL THEN 'No State'
        ELSE a.ca_state
    END AS shipping_state
FROM 
    sales_hierarchy ch
LEFT JOIN 
    customer_ranked cr ON ch.c_customer_sk = cr.c_customer_sk
LEFT JOIN 
    customer_address a ON ch.c_customer_sk = a.ca_address_sk
WHERE 
    (cr.rank <= 100 OR cr.total_profit IS NULL)
ORDER BY 
    cr.total_profit DESC,
    ch.c_last_name ASC;
