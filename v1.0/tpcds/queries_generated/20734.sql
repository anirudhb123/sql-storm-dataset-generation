
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
        AND ws_quantity > 0
), SalesAnalysis AS (
    SELECT
        item.i_item_id,
        i.i_item_desc,
        COALESCE(RankedSales.ws_sales_price, 0) AS max_price,
        SUM(RankedSales.ws_quantity) AS total_quantity,
        COUNT(RankedSales.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN RankedSales ON i.i_item_sk = RankedSales.ws_item_sk
    GROUP BY 
        item.i_item_id, i.i_item_desc
), MaxOrders AS (
    SELECT 
        item_id,
        MAX(order_count) AS max_order_count
    FROM 
        SalesAnalysis
    GROUP BY 
        item_id
)
SELECT 
    sa.item_id,
    sa.i_item_desc,
    sa.max_price,
    sa.total_quantity,
    mo.max_order_count
FROM 
    SalesAnalysis sa
JOIN 
    MaxOrders mo ON sa.item_id = mo.item_id
WHERE 
    sa.total_quantity IS NOT NULL 
    AND sa.max_price > (SELECT AVG(max_price) FROM SalesAnalysis)
ORDER BY 
    sa.total_quantity DESC, 
    sa.max_price ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
