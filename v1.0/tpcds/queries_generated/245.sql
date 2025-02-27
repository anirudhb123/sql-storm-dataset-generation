
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
),
HighValueSales AS (
    SELECT 
        rh.ws_item_sk,
        rh.ws_order_number,
        rh.ws_sales_price,
        rh.total_quantity_sold
    FROM 
        RankedSales rh
    WHERE 
        rh.price_rank = 1
        AND rh.total_quantity_sold > 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SUM(hv.total_quantity_sold), 0) AS total_quantity,
    COALESCE(AVG(hv.ws_sales_price), 0) AS avg_sales_price,
    CASE 
        WHEN SUM(hv.total_quantity_sold) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS sales_status
FROM 
    item i
LEFT JOIN 
    HighValueSales hv ON i.i_item_sk = hv.ws_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc
HAVING 
    sales_status = 'Active' OR avg_sales_price > 100
ORDER BY 
    total_quantity DESC NULLS LAST;
