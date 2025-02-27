
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
promotional_sales AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_ext_sales_price,
        cs_quantity 
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 20220101 AND 20221231
        AND cs_promo_sk IN (SELECT p_promo_sk FROM promotion WHERE p_channel_email = 'Y')
),
warehouse_sales AS (
    SELECT 
        w_warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        warehouse ON ws_warehouse_sk = w_warehouse_sk
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        w_warehouse_id
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_sales_price,
    p.cs_quantity,
    w.warehouse_id,
    w.total_sales
FROM 
    sales_rank r
LEFT JOIN 
    promotional_sales p ON r.ws_order_number = p.cs_order_number AND r.ws_item_sk = p.cs_item_sk
LEFT JOIN 
    warehouse_sales w ON r.ws_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales WHERE ws_order_number = r.ws_order_number)
WHERE 
    r.rank <= 5
    AND (p.cs_quantity IS NOT NULL OR w.total_sales IS NOT NULL)
ORDER BY 
    r.ws_sales_price DESC, 
    p.cs_quantity DESC;
