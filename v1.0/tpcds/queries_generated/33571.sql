
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_ext_sales_price,
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_order_number IN (SELECT ws_order_number FROM sales_data)
)
SELECT 
    item.i_item_id,
    SUM(sales_data.ws_ext_sales_price) AS total_web_sales,
    SUM(sales_data.cs_ext_sales_price) AS total_catalog_sales,
    COUNT(DISTINCT sales_data.ws_order_number) AS order_count_web,
    COUNT(DISTINCT sales_data.cs_order_number) AS order_count_catalog,
    COUNT(DISTINCT customer.c_customer_id) AS total_customers,
    CASE 
        WHEN SUM(sales_data.ws_ext_sales_price) IS NULL THEN 'No Web Sales'
        ELSE 'Web Sales Available'
    END AS web_sales_status
FROM 
    sales_data
JOIN 
    item ON item.i_item_sk = sales_data.ws_item_sk
JOIN 
    customer ON customer.c_customer_sk = sales_data.ws_order_number
GROUP BY 
    item.i_item_id
HAVING 
    total_web_sales > 1000
ORDER BY 
    total_web_sales DESC
LIMIT 10;
