
WITH CustomerStores AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cs.c_customer_id,
        cs.full_name,
        d.d_date
    FROM 
        web_sales AS ws
    JOIN 
        CustomerStores AS cs ON ws.ws_bill_customer_sk = cs.c_customer_id
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
),
AggregatedSales AS (
    SELECT 
        full_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        SalesData
    GROUP BY 
        full_name
)
SELECT 
    CONCAT('Customer: ', full_name) AS customer_info,
    total_quantity,
    total_net_profit,
    total_orders
FROM 
    AggregatedSales
WHERE 
    total_net_profit > 1000
ORDER BY 
    total_net_profit DESC;
