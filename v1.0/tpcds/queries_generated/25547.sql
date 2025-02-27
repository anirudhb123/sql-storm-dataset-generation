
WITH CustomerLocation AS (
    SELECT 
        c.c_customer_id,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        c.c_first_name,
        c.c_last_name,
        c.c_city,
        c.c_state,
        c.c_zip
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        c.c_customer_id,
        cl.full_address
    FROM 
        web_sales ws
    JOIN 
        CustomerLocation cl ON ws.ws_bill_customer_sk = cl.c_customer_id
),
CustomerSales AS (
    SELECT 
        c.customer_id,
        COUNT(s.ws_order_number) AS total_orders,
        SUM(s.ws_ext_sales_price) AS total_sales,
        SUM(s.ws_ext_tax) AS total_tax,
        SUM(s.ws_net_profit) AS total_profit,
        MIN(s.ws_order_number) AS first_order,
        MAX(s.ws_order_number) AS last_order
    FROM 
        CustomerLocation c
    LEFT JOIN 
        SalesData s ON s.c_customer_id = c.c_customer_id
    GROUP BY 
        c.customer_id
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    cl.full_address,
    cs.total_orders,
    cs.total_sales,
    cs.total_tax,
    cs.total_profit,
    cs.first_order,
    cs.last_order
FROM 
    CustomerLocation cl
JOIN 
    CustomerSales cs ON cl.c_customer_id = cs.customer_id
JOIN 
    customer c ON c.c_customer_id = cs.customer_id
ORDER BY 
    cs.total_profit DESC
LIMIT 10;
