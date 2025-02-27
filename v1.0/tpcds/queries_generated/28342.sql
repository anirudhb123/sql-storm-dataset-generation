
WITH CustomerLocation AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        cl.customer_full_name,
        cl.ca_city,
        cl.ca_state,
        cl.ca_country
    FROM 
        web_sales ws
    JOIN 
        CustomerLocation cl ON ws.ws_bill_customer_sk = c.c_customer_sk
),
AggregatedSales AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        SalesData
    GROUP BY 
        ca_city, ca_state, ca_country
)
SELECT 
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    order_count,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    AggregatedSales
WHERE 
    total_sales > 10000
ORDER BY 
    total_sales DESC;
