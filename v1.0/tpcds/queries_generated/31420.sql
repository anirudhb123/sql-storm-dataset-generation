
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS recency_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)

    UNION ALL

    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS recency_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
)

SELECT 
    item.i_item_id,
    item.i_item_desc,
    SUM(sd.ws_quantity + sd.cs_quantity) AS total_quantity,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    AVG(sd.ws_sales_price + sd.cs_sales_price) AS avg_price,
    CASE 
        WHEN AVG(sd.ws_sales_price + sd.cs_sales_price) IS NULL THEN 'No Sales'
        WHEN AVG(sd.ws_sales_price + sd.cs_sales_price) < 10 THEN 'Low Price'
        WHEN AVG(sd.ws_sales_price + sd.cs_sales_price) BETWEEN 10 AND 50 THEN 'Medium Price'
        ELSE 'High Price'
    END AS price_category
FROM 
    sales_data sd
JOIN 
    item ON sd.ws_item_sk = item.i_item_sk OR sd.cs_item_sk = item.i_item_sk
GROUP BY 
    item.i_item_id, item.i_item_desc
HAVING 
    total_quantity > 100
ORDER BY 
    total_orders DESC
LIMIT 10;
