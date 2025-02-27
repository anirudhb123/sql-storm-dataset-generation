
WITH RECURSIVE SalesPath AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        level + 1
    FROM catalog_sales
    WHERE cs_order_number IN (SELECT ws_order_number FROM SalesPath)
)
SELECT 
    wsm.sm_type,
    SUM(sp.ws_sales_price * sp.ws_quantity) AS Total_Sales,
    AVG(sp.ws_sales_price) AS Avg_Sales_Price,
    COUNT(DISTINCT sp.ws_order_number) AS Total_Orders,
    MAX(sp.ws_sales_price) AS Max_Single_Sale,
    MIN(sp.ws_sales_price) AS Min_Single_Sale
FROM SalesPath sp
LEFT JOIN ship_mode wsm ON sp.ws_item_sk = wsm.sm_ship_mode_sk
LEFT JOIN inventory iv ON sp.ws_item_sk = iv.inv_item_sk
WHERE 
    iv.inv_quantity_on_hand > 0
    AND (sp.ws_sales_price IS NOT NULL OR sp.ws_sales_price > 0)
GROUP BY wsm.sm_type
HAVING Total_Sales > 1000
ORDER BY Total_Sales DESC
LIMIT 10;
