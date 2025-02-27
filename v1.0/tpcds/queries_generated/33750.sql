
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_sales_price) > 1000
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        s.total_sales,
        s.order_count,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk AND p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim) AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    WHERE 
        s.rn <= 10
)
SELECT 
    b.i_item_id,
    b.total_sales,
    b.order_count,
    b.promo_name,
    COALESCE(sm.sm_ship_mode_id, 'Unknown') AS shipping_mode,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL AND (c.c_birth_year < 1980) ) AS customer_count
FROM 
    BestSellingItems b
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk IN (SELECT DISTINCT ws_ship_mode_sk FROM web_sales WHERE ws_item_sk = b.i_item_id)
ORDER BY 
    total_sales DESC;
