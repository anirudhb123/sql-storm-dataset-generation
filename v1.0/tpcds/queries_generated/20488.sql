
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
high_profit_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.total_profit,
        ss.total_orders
    FROM 
        customer c
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.bill_customer_sk
    WHERE 
        ss.profit_rank <= 10
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    hpc.c_customer_id,
    hpc.c_first_name,
    hpc.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ai.customer_count,
    COALESCE(hpc.total_profit, 0) AS total_profit,
    (SELECT 
        SUM(ws_ext_tax) 
    FROM 
        web_sales ws 
    WHERE 
        ws.bill_customer_sk = hpc.bill_customer_sk 
        AND ws.ws_sold_date_sk > (
            SELECT MAX(ws2.ws_sold_date_sk) 
            FROM web_sales ws2 
            WHERE ws2.bill_customer_sk = hpc.bill_customer_sk AND ws2.ws_sold_date_sk <= 20230101
        )
    ) AS future_tax_contributions
FROM 
    high_profit_customers hpc
LEFT JOIN 
    address_info ai ON ai.customer_count > 5
WHERE 
    ai.ca_city IS NOT NULL
ORDER BY 
    hpc.total_profit DESC, hpc.c_last_name ASC;
