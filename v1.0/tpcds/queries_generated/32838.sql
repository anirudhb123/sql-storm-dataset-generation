
WITH RECURSIVE previous_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        ps.level + 1
    FROM 
        web_sales ws
    JOIN 
        previous_sales ps ON ws.ws_item_sk = ps.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk < ps.ws_sold_date_sk
)

SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS average_profit,
    MAX(ws_ext_discount_amt) AS max_discount,
    STRING_AGG(DISTINCT c_last_name || ', ' || c_first_name) AS customer_names,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year IS NOT NULL) AS total_customers_with_birth_year
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    EXISTS (SELECT 1 FROM previous_sales ps WHERE ps.ws_item_sk = ws.ws_item_sk)
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10
OFFSET 5;
