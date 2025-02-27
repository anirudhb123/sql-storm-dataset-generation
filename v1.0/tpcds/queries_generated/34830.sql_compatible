
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        ws_order_number,
        ws_ext_sales_price,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        sr_customer_sk,
        sr_ticket_number,
        sr_return_amt AS ws_ext_sales_price,
        sh.level + 1
    FROM 
        store_returns sr
    JOIN 
        sales_hierarchy sh ON sr_ticket_number = sh.ws_order_number
    WHERE 
        sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
    COUNT(DISTINCT sh.customer_sk) AS total_customers,
    AVG(ws.ws_ext_sales_price) AS average_sale,
    MAX(ws.ws_ext_sales_price) AS max_sale,
    MIN(ws.ws_ext_sales_price) AS min_sale
FROM 
    sales_hierarchy sh
JOIN 
    customer_demographics cd ON sh.customer_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON ws.ws_order_number = sh.ws_order_number
LEFT JOIN 
    item i ON i.i_item_sk = ws.ws_item_sk
WHERE 
    cd.cd_marital_status IN ('M', 'S') 
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) > 100000 
ORDER BY 
    total_sales DESC
LIMIT 10;
