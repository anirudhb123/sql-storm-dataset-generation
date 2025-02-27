
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

web_sales_info AS (
    SELECT 
        ws.fs_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),

formatted_sales_info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        COALESCE(wsi.total_sales, 0) AS total_sales,
        COALESCE(wsi.order_count, 0) AS order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        web_sales_info wsi ON ci.c_customer_sk = wsi.fs_bill_customer_sk
)

SELECT 
    *,
    CASE 
        WHEN order_count > 0 THEN 
            ROUND(total_sales / order_count, 2) 
        ELSE 0 
    END AS average_order_value,
    UPPER(CONCAT(ca_city, ', ', ca_state)) AS location
FROM 
    formatted_sales_info
WHERE 
    total_sales > 1000
ORDER BY 
    average_order_value DESC
LIMIT 100;
