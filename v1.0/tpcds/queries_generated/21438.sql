
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity * (CASE WHEN rs.ws_sales_price > 100 THEN 0.9 ELSE 1 END) AS adjusted_quantity,
        SUM(CASE WHEN d.d_week_seq % 2 = 0 THEN rs.ws_quantity ELSE 0 END) AS even_week_sales
    FROM 
        RankedSales rs
    JOIN 
        date_dim d ON rs.ws_sold_date_sk = d.d_date_sk
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_order_number, rs.ws_item_sk
    HAVING 
        SUM(rs.ws_quantity) > 5
)

SELECT 
    ws_item_sk,
    SUM(adjusted_quantity) AS total_adjusted_quantity,
    COUNT(DISTINCT ws_order_number) AS order_count,
    CASE 
        WHEN SUM(adjusted_quantity) > (SELECT AVG(adjusted_quantity) FROM FilteredSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_category
FROM 
    FilteredSales
GROUP BY 
    ws_item_sk
ORDER BY 
    total_adjusted_quantity DESC
LIMIT 10

UNION ALL

SELECT 
    isnull(item.i_item_sk, -1) AS ws_item_sk,
    SUM(COALESCE(im.inv_quantity_on_hand, 0)) AS total_adjusted_quantity,
    COUNT(DISTINCT sr_ticket_number) AS order_count,
    'Inventory Check' AS sales_category
FROM 
    item
LEFT JOIN 
    inventory im ON item.i_item_sk = im.inv_item_sk AND im.inv_quantity_on_hand IS NOT NULL
LEFT JOIN 
    store_returns sr ON item.i_item_sk = sr.sr_item_sk
WHERE 
    item.i_current_price > 50
GROUP BY 
    item.i_item_sk
ORDER BY 
    total_adjusted_quantity DESC
LIMIT 10;
