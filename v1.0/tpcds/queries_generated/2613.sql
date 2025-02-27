
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(rs.ws_sales_price, 0) AS highest_sales_price,
        COALESCE(rs.ws_net_profit, 0) AS highest_net_profit,
        COUNT(*)
    FROM 
        item
    LEFT JOIN 
        ranked_sales rs ON item.i_item_sk = rs.ws_item_sk AND rs.rn = 1
    WHERE 
        item.i_current_price > 0 
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
sales_summary AS (
    SELECT 
        tds.i_item_id,
        tds.i_item_desc,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        top_sales tds
    LEFT JOIN 
        store_sales ss ON tds.i_item_id = ss.ss_item_sk
    GROUP BY 
        tds.i_item_id, tds.i_item_desc
)

SELECT 
    s_summary.i_item_id,
    s_summary.i_item_desc,
    s_summary.total_quantity_sold,
    s_summary.total_net_paid,
    s_summary.avg_sales_price,
    CASE 
        WHEN s_summary.total_net_paid IS NULL THEN 'No Sales'
        WHEN s_summary.total_quantity_sold > 100 THEN 'High Demand'
        ELSE 'Regular Demand'
    END AS demand_category
FROM 
    sales_summary s_summary
WHERE 
    s_summary.avg_sales_price > (
        SELECT 
            AVG(ws_sales_price) 
        FROM 
            web_sales
        WHERE 
            ws_sales_price IS NOT NULL
    )
ORDER BY 
    s_summary.total_net_paid DESC
LIMIT 10;
