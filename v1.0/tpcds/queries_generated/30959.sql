
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk BETWEEN 40000 AND 40010 
    GROUP BY 
        ws_order_number, ws_item_sk
    
    UNION ALL
    
    SELECT
        cs_order_number,
        cs_item_sk,
        SUM(cs_quantity),
        SUM(cs_ext_sales_price)
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk BETWEEN 40000 AND 40010 
    GROUP BY 
        cs_order_number, cs_item_sk
)

SELECT 
    COALESCE(ws_item_desc, cs_item_desc) AS item_description,
    COALESCE(ws_order_number, cs_order_number) AS order_number,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_sales_value
FROM 
    (SELECT 
        i.i_item_desc, 
        s.Total_quantity, 
        s.total_sales, 
        s.ws_order_number 
     FROM 
         SalesCTE s 
     LEFT JOIN 
         item i ON s.ws_item_sk = i.i_item_sk 
     
     UNION ALL 
     
     SELECT 
        i.i_item_desc, 
        s.Total_quantity, 
        s.total_sales, 
        s.cs_order_number 
     FROM 
         SalesCTE s 
     LEFT JOIN 
         item i ON s.cs_item_sk = i.i_item_sk) AS combined_sales
LEFT JOIN 
    store s ON combined_sales.order_number = s.s_store_id 
GROUP BY 
    item_description, order_number
ORDER BY 
    total_sales_value DESC
LIMIT 100;
