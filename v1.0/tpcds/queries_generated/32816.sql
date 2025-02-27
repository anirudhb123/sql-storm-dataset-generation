
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
high_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(ss.total_sales) AS accum_sales,
        SUM(ss.total_revenue) AS accum_revenue
    FROM 
        sales_summary ss
    JOIN 
        item ON ss.ws_item_sk = item.i_item_sk
    WHERE 
        ss.rn = 1
    GROUP BY 
        item.i_item_id, item.i_item_desc
    HAVING 
        accum_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                sales_summary
        )
)
SELECT 
    h.i_item_id,
    h.i_item_desc,
    h.accum_sales,
    h.accum_revenue,
    COALESCE(NULLIF(h.accum_sales, 0), 1) AS safe_accum_sales,
    h.accum_revenue / COALESCE(NULLIF(h.accum_sales, 0), 1) AS avg_revenue_per_sale,
    (SELECT COUNT(DISTINCT ss.ws_sold_date_sk) FROM sales_summary ss WHERE ss.ws_item_sk = h.i_item_id) AS sales_days
FROM 
    high_sales h
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT ss.ss_store_sk 
                                FROM store_sales ss 
                                WHERE ss.ss_item_sk = h.i_item_id 
                                ORDER BY ss.ss_sold_date_sk DESC LIMIT 1)
WHERE 
    s.s_state = 'CA' OR s.s_state IS NULL
ORDER BY 
    h.accum_sales DESC
LIMIT 100;
