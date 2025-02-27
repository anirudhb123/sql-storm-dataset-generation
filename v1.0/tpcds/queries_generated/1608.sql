
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 3 LIMIT 1) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 3 ORDER BY d_date_sk DESC LIMIT 1)
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    a.ca_state,
    COUNT(DISTINCT cs.c_customer_id) AS customer_count,
    SUM(COALESCE(cs.total_net_profit, 0)) AS total_profit,
    (SELECT COUNT(*) FROM ranked_sales rs WHERE rs.rank_profit <= 10) AS top_sales_count
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_sales cs ON c.c_customer_id = cs.c_customer_id
WHERE 
    a.ca_state IS NOT NULL
GROUP BY 
    a.ca_state
ORDER BY 
    total_profit DESC
LIMIT 5;
