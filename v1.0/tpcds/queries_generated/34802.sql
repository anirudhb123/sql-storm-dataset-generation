
WITH RECURSIVE sales_totals AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_item_sk
),
current_year_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS web_total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
sales_combined AS (
    SELECT 
        s.ss_item_sk,
        total_sales,
        COALESCE(web_total_sales, 0) AS web_total_sales,
        total_sales + COALESCE(web_total_sales, 0) AS grand_total_sales
    FROM 
        sales_totals s 
        LEFT JOIN current_year_sales w ON s.ss_item_sk = w.ws_item_sk
)
SELECT 
    s.ss_item_sk,
    s.total_sales,
    s.web_total_sales,
    s.grand_total_sales,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = s.ss_item_sk) AS total_returns,
    CASE 
        WHEN s.grand_total_sales > 10000 THEN 'High Volume'
        WHEN s.grand_total_sales > 5000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    sales_combined s
WHERE 
    s.grand_total_sales IS NOT NULL
ORDER BY 
    s.grand_total_sales DESC
LIMIT 10;
