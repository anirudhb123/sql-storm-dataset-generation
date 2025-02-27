
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk >= 20200101) AS sales_count,
        0 AS level
    FROM 
        item i
    WHERE 
        i.i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns)

    UNION ALL

    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk >= 20200101) AS sales_count,
        ih.level + 1
    FROM 
        item_hierarchy ih
    JOIN 
        item i ON i.i_item_sk = ih.i_item_sk  -- Simulated self-join; adjust as necessary
    WHERE 
        ih.level < 5 
), top_sales AS (
    SELECT 
        ihi.i_item_desc,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        item_hierarchy ihi
    JOIN 
        web_sales ws ON ws.ws_item_sk = ihi.i_item_sk
    GROUP BY 
        ihi.i_item_desc
),
filtered_sales AS (
    SELECT 
        t.total_net_profit,
        t.total_orders,
        t.sales_rank,
        CASE 
            WHEN t.total_net_profit IS NULL THEN 'No Sales'
            WHEN t.total_orders = 0 THEN 'No Orders'
            ELSE 'Sales Recorded'
        END AS sales_status
    FROM 
        top_sales t
    WHERE 
        t.sales_rank <= 10
)
SELECT 
    f.total_net_profit,
    f.total_orders,
    f.sales_rank,
    f.sales_status,
    COALESCE(ROUND(f.total_net_profit / NULLIF(f.total_orders, 0), 2), 0) AS avg_profit_per_order
FROM 
    filtered_sales f
WHERE 
    f.total_net_profit IS NOT NULL
ORDER BY 
    f.sales_rank;
