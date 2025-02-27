
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
FilteredSales AS (
    SELECT 
        r.ws_item_sk, 
        r.ws_order_number, 
        r.ws_net_paid,
        cs.cs_net_paid AS catalog_net_paid,
        ss.ss_net_paid AS store_net_paid
    FROM 
        RankedSales r
    LEFT JOIN catalog_sales cs ON r.ws_item_sk = cs.cs_item_sk AND r.ws_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss ON r.ws_item_sk = ss.ss_item_sk AND r.ws_order_number = ss.ss_ticket_number
    WHERE 
        rnk = 1
),
AggregatedSales AS (
    SELECT 
        fs.ws_item_sk,
        COUNT(DISTINCT fs.ws_order_number) AS total_orders,
        COALESCE(SUM(fs.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(fs.catalog_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(fs.store_net_paid), 0) AS total_store_sales,
        CASE 
            WHEN COUNT(DISTINCT fs.ws_order_number) = 0 THEN 'No Sales'
            WHEN SUM(fs.ws_net_paid) > 5000 THEN 'High Sales'
            ELSE 'Regular Sales'
        END AS sales_category
    FROM 
        FilteredSales fs
    GROUP BY 
        fs.ws_item_sk
)
SELECT 
    a.ws_item_sk, 
    a.total_orders,
    a.total_web_sales,
    a.total_catalog_sales,
    a.total_store_sales,
    a.sales_category,
    CASE 
        WHEN a.total_web_sales > 0 THEN 'Web Sales: ' || CAST(a.total_web_sales AS VARCHAR(20))
        ELSE 'No Web Sales'
    END AS web_sales_info
FROM 
    AggregatedSales a
WHERE 
    a.sales_category != 'No Sales'
ORDER BY 
    a.total_web_sales DESC, a.total_orders DESC
LIMIT 10;

-- Find previous day's sales records and potential trends
SELECT 
    d.d_date,
    SUM(ws.ws_net_paid) AS total_web,
    SUM(cs.cs_net_paid) AS total_catalog,
    SUM(ss.ss_net_paid) AS total_store,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'Web Sales Inactive'
        WHEN SUM(cs.cs_net_paid) IS NULL THEN 'Catalog Inactive'
        ELSE 'Active Sales'
    END AS sales_activity
FROM 
    date_dim d
LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk 
LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk 
LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk 
WHERE 
    d.d_date = CURRENT_DATE - INTERVAL '1 DAY'
GROUP BY 
    d.d_date;
