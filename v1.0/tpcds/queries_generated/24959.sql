
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_paid, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS recent_sales
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0
),
aggregated_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        AVG(sd.ws_net_paid) AS avg_net_paid,
        COUNT(*) AS num_sales
    FROM 
        sales_data sd
    WHERE 
        sd.recent_sales <= 3
    GROUP BY 
        sd.ws_item_sk
),
high_value_items AS (
    SELECT 
        a.ws_item_sk, 
        CASE 
            WHEN AVG(a.total_net_paid) IS NULL THEN 'Unknown'
            WHEN AVG(a.total_net_paid) >= 100 THEN 'High'
            WHEN AVG(a.total_net_paid) BETWEEN 50 AND 99 THEN 'Medium'
            ELSE 'Low'
        END AS value_category
    FROM 
        aggregated_sales a
    GROUP BY 
        a.ws_item_sk
),
items_info AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        hvi.value_category,
        COALESCE(NULLIF(MAX(i.i_current_price), 0), 1) AS current_price 
    FROM 
        item i 
    LEFT JOIN 
        high_value_items hvi ON i.i_item_sk = hvi.ws_item_sk
    GROUP BY 
        i.i_item_id, 
        i.i_item_desc, 
        hvi.value_category
)
SELECT 
    ii.i_item_id, 
    ii.i_item_desc, 
    ii.value_category,
    ROUND(SUM(CASE WHEN si.ss_quantity IS NULL THEN 0 ELSE si.ss_quantity END) / NULLIF(SUM(CASE WHEN si.ss_item_sk IS NOT NULL THEN 1 ELSE 0 END), 0), 2) AS average_sales,
    STRING_AGG(DISTINCT w.w_warehouse_name, ', ') AS warehouse_names
FROM 
    items_info ii 
LEFT JOIN 
    store_sales si ON ii.i_item_id = si.ss_item_sk 
LEFT JOIN 
    warehouse w ON si.ss_store_sk = w.w_warehouse_sk
GROUP BY 
    ii.i_item_id, 
    ii.i_item_desc, 
    ii.value_category
HAVING 
    ALL (
        COUNT(CASE WHEN ii.value_category IS NULL THEN 1 END) = 0
        OR SUM(ii.current_price) > 0
    )
ORDER BY 
    ii.value_category DESC, 
    average_sales DESC;
