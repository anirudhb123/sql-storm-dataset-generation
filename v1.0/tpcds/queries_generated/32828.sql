
WITH RECURSIVE ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450886 AND 2452550
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(cs.total_sales) AS city_total_sales,
    AVG(cs.total_orders) AS avg_orders_per_customer,
    COUNT(DISTINCT cs.c_customer_id) AS num_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer_sales cs ON ca.ca_address_sk = cs.c_customer_id
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND (cs.total_sales IS NULL OR cs.total_sales > 1000)
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    city_total_sales > 50000
ORDER BY 
    city_total_sales DESC;
