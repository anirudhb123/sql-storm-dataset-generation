
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity,
        COALESCE(NULLIF(SUM(ws_quantity) OVER (PARTITION BY ws_item_sk), 0), 1) AS total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk = 1
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_item_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        item i
    LEFT JOIN 
        income_band ib ON (i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound)
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    id.i_current_price,
    id.i_item_desc,
    ts.ws_order_number,
    ts.ws_sales_price,
    ts.total_quantity,
    CASE 
        WHEN ts.total_quantity > 100 THEN 'High Volume'
        WHEN ts.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    COALESCE(CAST(NULLIF(ts.ws_sales_price, 0) AS DECIMAL(10,2)), id.i_current_price) AS effective_price,
    CASE 
        WHEN EXISTS (SELECT 1 FROM store_sales WHERE ss_item_sk = ts.ws_item_sk) THEN 'Sold in Store'
        ELSE 'Not Sold in Store'
    END AS store_sales_status
FROM 
    TopSales ts
JOIN 
    ItemDetails id ON ts.ws_item_sk = id.i_item_sk
WHERE 
    (id.i_current_price > 50 OR id.i_product_name LIKE '%premium%')
    AND (ts.ws_sales_price IS NOT NULL OR ts.ws_order_number IS NULL)
ORDER BY 
    id.i_product_name, 
    effective_price DESC
FETCH FIRST 100 ROWS ONLY;
