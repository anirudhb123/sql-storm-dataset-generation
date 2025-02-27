
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS sales_count,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
MostSoldItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.sales_count) AS total_sales
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        SUM(rs.sales_count) > 50
),
TopSoldItems AS (
    SELECT 
        mi.ws_item_sk,
        mi.total_sales,
        i.i_item_desc,
        i.i_current_price
    FROM 
        MostSoldItems mi
    JOIN 
        item i ON mi.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
),
PriceChanges AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_sales,
        ti.i_item_desc,
        ti.i_current_price,
        COALESCE((SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk = ti.ws_item_sk AND i2.i_rec_end_date IS NULL), 0) AS previous_price
    FROM 
        TopSoldItems ti
)
SELECT 
    pc.ws_item_sk,
    pc.i_item_desc,
    pc.total_sales,
    pc.i_current_price,
    pc.previous_price,
    CASE 
        WHEN pc.i_current_price > pc.previous_price THEN 'Increased'
        WHEN pc.i_current_price < pc.previous_price THEN 'Decreased'
        ELSE 'No Change'
    END AS price_change_status
FROM 
    PriceChanges pc
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT MIN(i.i_manufact_id) FROM item i WHERE i.i_item_sk = pc.ws_item_sk)
WHERE 
    w.w_country = 'US'
ORDER BY 
    pc.total_sales DESC, pc.i_item_desc;
