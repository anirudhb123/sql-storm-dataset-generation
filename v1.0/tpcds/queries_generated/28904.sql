
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_profit) DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),
FilteredSales AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        total_orders,
        total_profit
    FROM 
        RankedSales
    WHERE 
        city_rank <= 5
)
SELECT 
    fs.full_name,
    fs.ca_city,
    fs.ca_state,
    fs.total_orders,
    fs.total_profit,
    STRING_AGG(DISTINCT CONCAT('Customer ID: ', c.c_customer_id), '; ') AS customer_ids
FROM 
    FilteredSales fs
JOIN 
    customer c ON fs.full_name = CONCAT(c.c_first_name, ' ', c.c_last_name)
GROUP BY 
    fs.full_name, fs.ca_city, fs.ca_state, fs.total_orders, fs.total_profit
ORDER BY 
    fs.total_profit DESC;
