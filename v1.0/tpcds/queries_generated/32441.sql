
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_sold_date_sk,
        1 AS sale_level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        ws.bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        sd.sale_level + 1
    FROM 
        web_sales AS ws
    JOIN 
        sales_data AS sd ON ws.ws_bill_customer_sk = sd.ws_bill_customer_sk 
                         AND ws.ws_sold_date_sk < sd.ws_sold_date_sk
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT sd.ws_item_sk) AS total_items_purchased,
    SUM(sd.ws_quantity) AS total_quantity,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    SUM(sd.ws_ext_sales_price) AS total_sales
FROM 
    sales_data AS sd
JOIN 
    customer AS c ON sd.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (cd_demo_sk IS NOT NULL OR cd_marital_status IS NULL)
    AND sd.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT sd.ws_item_sk) > 5
ORDER BY 
    total_sales DESC
LIMIT 10
```
