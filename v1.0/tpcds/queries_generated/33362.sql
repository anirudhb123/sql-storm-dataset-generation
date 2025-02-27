
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity,
        ws_net_paid,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_sales_price, 
        cs_quantity,
        cs_net_paid,
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk < (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND cs_item_sk IN (SELECT ws_item_sk FROM web_sales)
)
SELECT 
    item.i_item_id, 
    item.i_item_desc,
    SUM(sales_data.ws_quantity) AS total_web_quantity,
    SUM(sales_data.cs_quantity) AS total_catalog_quantity,
    COUNT(DISTINCT sales_data.ws_order_number) AS unique_web_orders,
    COUNT(DISTINCT sales_data.cs_order_number) AS unique_catalog_orders,
    AVG(sales_data.ws_net_paid) AS avg_web_net_paid,
    AVG(sales_data.cs_net_paid) AS avg_catalog_net_paid,
    CASE 
        WHEN SUM(sales_data.ws_quantity) > SUM(sales_data.cs_quantity) THEN 'Web Sales Dominant'
        WHEN SUM(sales_data.ws_quantity) < SUM(sales_data.cs_quantity) THEN 'Catalog Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance
FROM 
    sales_data
JOIN 
    item ON sales_data.ws_item_sk = item.i_item_sk
GROUP BY 
    item.i_item_id, item.i_item_desc
ORDER BY 
    total_web_quantity DESC, avg_web_net_paid DESC
LIMIT 100;
