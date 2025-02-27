
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk 
                            FROM date_dim 
                            WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_statistics AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender
),
ranked_customers AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_net_profit DESC) AS gender_rank
    FROM 
        customer_statistics c
)
SELECT 
    a.ca_city,
    a.ca_state,
    SUM(sd.total_quantity) AS total_quantity,
    AVG(sd.total_net_profit) AS avg_net_profit,
    COUNT(DISTINCT rc.c_customer_sk) AS customer_count
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    sales_data sd ON c.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    ranked_customers rc ON c.c_customer_sk = rc.c_customer_sk AND rc.gender_rank <= 10
WHERE 
    a.ca_state IS NOT NULL 
    AND (a.ca_city LIKE '%Springfield%' OR a.ca_city LIKE '%River%')
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    COUNT(DISTINCT rc.c_customer_sk) > 5
ORDER BY 
    total_quantity DESC;
