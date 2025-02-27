
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
),
quarterly_summary AS (
    SELECT 
        d_year,
        d_quarter_seq,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        d_year, d_quarter_seq
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COALESCE(SUM(l.total_profit), 0) AS total_profit,
    AVG(ca.total_net_profit) FILTER (WHERE ca.total_net_profit IS NOT NULL) AS avg_customer_profit,
    MAX(q.total_quantity) AS max_quantity_sold
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_analysis ca ON ca.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    ranked_sales rs ON rs.ws_item_sk IN (
        SELECT i_item_sk 
        FROM item 
        WHERE i_brand LIKE 'A%' 
        AND i_current_price IS NOT NULL
    )
LEFT JOIN 
    quarterly_summary q ON q.d_year = 2023 AND q.d_quarter_seq = 1
GROUP BY 
    ca.city, 
    ca.state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > (
        SELECT COUNT(DISTINCT c2.c_customer_id) / 10 
        FROM customer c2 
        CROSS JOIN customer_demographics cd 
        WHERE cd.cd_gender = 'F'
    )
ORDER BY 
    total_profit DESC NULLS LAST;
