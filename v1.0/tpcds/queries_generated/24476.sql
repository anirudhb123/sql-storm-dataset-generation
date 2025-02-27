
WITH RECURSIVE sales_trend AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DATE(d_date) AS sales_date
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_quantity) > 0
    ORDER BY 
        sales_date ASC
),
item_performance AS (
    SELECT 
        i_item_id,
        i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY total_profit DESC) AS profit_rank,
        AVG(total_profit) OVER (PARTITION BY i_item_id) AS avg_profit
    FROM 
        sales_trend 
    JOIN 
        item ON sales_trend.ws_item_sk = item.i_item_sk
),
top_performers AS (
    SELECT 
        item_performance.i_item_id,
        item_performance.i_item_desc,
        item_performance.avg_profit,
        item_performance.profit_rank
    FROM 
        item_performance 
    WHERE 
        profit_rank = 1
),
store_sales_overview AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_net_profit) AS total_revenue
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    HAVING 
        total_quantity_sold > 100
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(ss.total_quantity_sold, 0) AS store_quantity,
    COALESCE(ss.total_revenue, 0) AS revenue,
    tp.i_item_id,
    tp.i_item_desc,
    tp.avg_profit
FROM 
    store_sales_overview ss
FULL OUTER JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    top_performers tp ON tp.avg_profit > (SELECT AVG(avg_profit) FROM top_performers)
WHERE 
    s.s_state = 'NY'
    AND (ss.total_revenue IS NULL OR ss.total_revenue > 5000)
ORDER BY 
    revenue DESC, store_quantity DESC
LIMIT 10;
