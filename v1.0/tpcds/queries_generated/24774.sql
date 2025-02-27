
WITH item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
catalog_info AS (
    SELECT 
        cs_item_sk,
        MAX(cs_sales_price) AS max_catalog_price,
        MIN(cs_sales_price) AS min_catalog_price
    FROM catalog_sales
    GROUP BY cs_item_sk
),
price_analysis AS (
    SELECT 
        i.i_item_id,
        COALESCE(is.total_quantity, 0) AS online_qty,
        COALESCE(ci.order_count, 0) AS catalog_orders,
        ci.max_catalog_price,
        ci.min_catalog_price,
        (COALESCE(is.total_sales, 0) - COALESCE(ci.max_catalog_price, 0)) AS price_difference
    FROM item i
    LEFT JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
    LEFT JOIN catalog_info ci ON i.i_item_sk = ci.cs_item_sk
),
high_performers AS (
    SELECT 
        pa.i_item_id,
        pa.online_qty,
        pa.catalog_orders,
        pa.max_catalog_price,
        pa.min_catalog_price,
        ROW_NUMBER() OVER (ORDER BY pa.online_qty DESC) AS rnk
    FROM price_analysis pa
    WHERE pa.price_difference > 0
),
potential_opportunities AS (
    SELECT 
        pa.i_item_id,
        pa.online_qty,
        pa.catalog_orders,
        pa.max_catalog_price,
        pa.min_catalog_price,
        LAG(pa.total_sales) OVER (ORDER BY pa.i_item_id) AS previous_sales,
        LEAD(pa.total_sales) OVER (ORDER BY pa.i_item_id) AS next_sales
    FROM price_analysis pa
    WHERE COALESCE(pa.max_catalog_price, 0) > 0
)
SELECT 
    h.i_item_id,
    h.online_qty,
    h.catalog_orders,
    h.max_catalog_price,
    h.min_catalog_price,
    CASE 
        WHEN h.catalog_orders = 0 THEN 'No orders'
        WHEN (h.online_qty * 0.1) < h.catalog_orders THEN 'Upsell opportunity'
        ELSE 'Stable performer'
    END AS performance_category,
    po.previous_sales,
    po.next_sales
FROM high_performers h
FULL OUTER JOIN potential_opportunities po ON h.i_item_id = po.i_item_id
WHERE (h.online_qty > 100 OR po.catalog_orders IS NOT NULL)
ORDER BY h.online_qty DESC, po.catalog_orders ASC
LIMIT 100
OFFSET 10;
