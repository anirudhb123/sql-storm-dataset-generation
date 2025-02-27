
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
AggregateSales AS (
    SELECT 
        i.i_item_id,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_price,
        COUNT(DISTINCT rs.ws_quantity) AS distinct_quantity_count
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rn = 1
    GROUP BY 
        i.i_item_id
), 
SalesWithPromotion AS (
    SELECT 
        asales.i_item_id,
        asales.total_sales,
        asales.avg_price,
        CASE 
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS promo_status
    FROM 
        AggregateSales asales
    LEFT JOIN 
        promotion p ON p.p_item_sk = asales.i_item_id
)
SELECT 
    swp.i_item_id,
    swp.total_sales,
    swp.avg_price,
    swp.promo_status,
    COALESCE(c.cc_call_center_id, 'No Call Center') AS call_center_id,
    MAX(w.w_warehouse_id) AS warehouse_id
FROM 
    SalesWithPromotion swp
LEFT JOIN 
    call_center c ON swp.i_item_id IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = swp.i_item_id)
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = swp.i_item_id
LEFT JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    swp.i_item_id, swp.total_sales, swp.avg_price, swp.promo_status, c.cc_call_center_id
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
