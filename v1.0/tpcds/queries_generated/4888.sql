
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(sd.total_quantity, 0) > 0 THEN ROUND(COALESCE(sd.total_sales, 0) / COALESCE(sd.total_quantity, 1), 2)
        ELSE 0
    END AS avg_sales_price,
    id.discount_active
FROM 
    ItemDetails id
LEFT JOIN 
    SalesData sd ON id.i_item_sk = sd.ws_item_sk
WHERE 
    id.i_current_price > (
        SELECT AVG(i_current_price) 
        FROM item 
        WHERE i_current_price IS NOT NULL
    )
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
