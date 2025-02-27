
WITH not_canceled_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL 
        AND ws_sales_price > 0 
    GROUP BY 
        ws_item_sk
),
ranked_sales AS (
    SELECT 
        item.i_item_id,
        sales.total_quantity,
        sales.total_sales,
        sales.total_orders,
        CASE 
            WHEN sales.total_sales > 10000 THEN 'High'
            WHEN sales.total_sales BETWEEN 1000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM 
        not_canceled_sales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        promotion p ON sales.ws_item_sk = p.p_item_sk AND p.p_start_date_sk <= current_date AND (p.p_end_date_sk IS NULL OR p.p_end_date_sk >= current_date)
    WHERE 
        sales.sales_rank <= 10
)
SELECT 
    r.item_id,
    r.total_quantity,
    r.total_sales,
    r.total_orders,
    r.sales_category,
    cnt.calls_made,
    COALESCE(wa.warehouse_name, 'Unknown Warehouse') AS warehouse_name
FROM 
    ranked_sales r
LEFT JOIN 
    (SELECT 
        c.cc_call_center_sk,
        COUNT(*) AS calls_made
     FROM 
        call_center c
     JOIN 
        store s ON c.cc_store_sk = s.s_store_sk
     GROUP BY 
        c.cc_call_center_sk) cnt ON r.total_orders = cnt.calls_made
LEFT JOIN 
    warehouse wa ON wa.w_warehouse_sk = r.total_quantity % 5
WHERE 
    r.discount_active = 'Y' 
    OR (r.discount_active = 'N' AND r.total_sales IS NOT NULL)
ORDER BY 
    r.total_sales DESC, 
    r.item_id ASC
FETCH FIRST 20 ROWS ONLY;
