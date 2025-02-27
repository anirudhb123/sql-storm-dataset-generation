
WITH RECURSIVE sales_analytics AS (
    SELECT 
        ws.sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
    GROUP BY 
        ws.sold_date_sk
),
date_range AS (
    SELECT MIN(d.d_date_sk) AS start_date, MAX(d.d_date_sk) AS end_date
    FROM date_dim d
    WHERE d.d_year = 2023
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date_sk,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        (c.c_birth_month = 12 AND c.c_birth_day = 25) OR total_orders > 5
)
SELECT 
    d.d_date_id,
    sa.total_quantity,
    sa.total_profit,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count
FROM 
    date_dim d
LEFT JOIN 
    sales_analytics sa ON d.d_date_sk = sa.sold_date_sk
LEFT JOIN 
    high_value_customers hvc ON hvc.d_date_sk = d.d_date_sk
WHERE 
    d.d_date_sk BETWEEN (SELECT start_date FROM date_range) AND (SELECT end_date FROM date_range)
GROUP BY 
    d.d_date_id, sa.total_quantity, sa.total_profit
ORDER BY 
    d.d_date_id;
