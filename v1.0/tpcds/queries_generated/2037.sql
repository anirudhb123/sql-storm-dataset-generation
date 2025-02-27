
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
store_summary AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity_store,
        SUM(ss_net_paid) AS total_sales_store
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
),
total_sales AS (
    SELECT 
        ds.d_date,
        COALESCE(ws.total_quantity, 0) AS web_sales_quantity,
        COALESCE(ss.total_quantity_store, 0) AS store_sales_quantity,
        COALESCE(ws.total_sales, 0) AS web_sales_total,
        COALESCE(ss.total_sales_store, 0) AS store_sales_total,
        (COALESCE(ws.total_sales, 0) + COALESCE(ss.total_sales_store, 0)) AS combined_sales_total
    FROM 
        date_dim ds
    LEFT JOIN 
        sales_summary ws ON ds.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_summary ss ON ds.d_date_sk = ss.ss_sold_date_sk AND ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        ds.d_year = 2023
)
SELECT 
    ds.d_date,
    COALESCE(wp.url, 'Unknown') AS web_page_url,
    ts.web_sales_quantity,
    ts.store_sales_quantity,
    ts.web_sales_total,
    ts.store_sales_total,
    ts.combined_sales_total,
    CASE 
        WHEN ts.combined_sales_total > 10000 THEN 'High Sales'
        WHEN ts.combined_sales_total BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    total_sales ts
OUTER APPLY (
    SELECT 
        wp.web_page_sk, wp.wp_url 
    FROM 
        web_page wp 
    WHERE 
        wp.wp_creation_date_sk = ts.ws_sold_date_sk OR wp.wp_access_date_sk = ts.ws_sold_date_sk
) wp
WHERE 
    ts.combined_sales_total > (
        SELECT AVG(combined_sales_total) 
        FROM total_sales 
        WHERE combined_sales_total IS NOT NULL
    )
ORDER BY 
    ts.combined_sales_total DESC
LIMIT 100;
