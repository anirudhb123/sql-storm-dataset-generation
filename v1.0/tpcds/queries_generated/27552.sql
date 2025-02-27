
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(CONCAT(c.ca_street_number, ' ', c.ca_street_name, ' ', c.ca_street_type)) AS full_address,
        d.d_date AS sale_date,
        ws.ws_sales_price,
        ws.ws_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
aggregated_data AS (
    SELECT 
        full_name,
        COUNT(*) AS total_purchases,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        processed_data
    GROUP BY 
        full_name
)
SELECT 
    full_name,
    total_purchases,
    total_sales,
    avg_profit,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    aggregated_data
ORDER BY 
    total_sales DESC, 
    total_purchases DESC
LIMIT 50;
