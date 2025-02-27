
WITH RECURSIVE address_cte AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ca_zip,
        1 AS level
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    UNION ALL
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ca_zip,
        level + 1
    FROM 
        customer_address c
    JOIN 
        address_cte a ON c.ca_city = a.ca_city AND c.ca_state = a.ca_state
    WHERE 
        c.ca_zip IS NOT NULL AND a.level < 5
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_price,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    c.c_customer_id,
    cs.total_profit,
    cs.order_count,
    COALESCE(SUM(i.total_quantity), 0) AS total_item_sold,
    COALESCE(SUM(i.avg_price), 0) AS total_avg_price,
    COALESCE(SUM(i.max_profit), 0) AS total_max_profit,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    a.ca_zip
FROM 
    customer c
LEFT JOIN 
    customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    item_summary i ON i.i_item_sk IN (SELECT i.i_item_sk FROM web_sales ws)
LEFT JOIN 
    address_cte a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    cs.order_count > 10 
    AND (cs.total_profit > 1000 OR cs.total_profit IS NULL)
GROUP BY 
    c.c_customer_id, cs.total_profit, cs.order_count, a.ca_city, a.ca_state, a.ca_country, a.ca_zip
ORDER BY 
    cs.total_profit DESC
LIMIT 100;
