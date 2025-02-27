
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        rn + 1
    FROM catalog_sales cs 
    JOIN SalesCTE cte ON cs.cs_item_sk = cte.ws_item_sk 
    WHERE cte.rn < 5
),
TotalSales AS (
    SELECT 
        item.i_item_id,
        COALESCE(SUM(s.ws_net_paid), 0) AS online_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS store_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS catalog_sales
    FROM item
    LEFT JOIN web_sales s ON item.i_item_sk = s.ws_item_sk
    LEFT JOIN store_sales ss ON item.i_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_sales cs ON item.i_item_sk = cs.cs_item_sk
    GROUP BY item.i_item_id
),
SalesRanked AS (
    SELECT 
        ts.i_item_id,
        ts.online_sales,
        ts.store_sales,
        ts.catalog_sales,
        RANK() OVER (ORDER BY (ts.online_sales + ts.store_sales + ts.catalog_sales) DESC) AS sales_rank
    FROM TotalSales ts
),
FilteredSales AS (
    SELECT 
        sr.i_item_id,
        sr.online_sales,
        sr.store_sales,
        sr.catalog_sales
    FROM SalesRanked sr
    WHERE sr.sales_rank <= 10
)
SELECT 
    fa.ca_city,
    SUM(fs.online_sales) AS total_online_sales,
    SUM(fs.store_sales) AS total_store_sales,
    SUM(fs.catalog_sales) AS total_catalog_sales,
    CASE 
        WHEN SUM(fs.online_sales) IS NULL OR SUM(fs.online_sales) = 0 THEN 'No sales online'
        ELSE 'Sales data available'
    END AS online_sales_status,
    COUNT(DISTINCT fs.i_item_id) AS unique_items_sold,
    AVG(NULLIF(fs.catalog_sales, 0)) OVER () AS avg_catalog_sales_per_item
FROM FilteredSales fs
JOIN customer_address fa ON fa.ca_address_sk = (
        SELECT c.c_current_addr_sk
        FROM customer c
        WHERE c.c_customer_sk = (
            SELECT MIN(wr.w_returning_customer_sk)
            FROM web_returns wr
            JOIN web_sales ws ON ws.ws_customer_sk = wr.w_refunded_customer_sk
            GROUP BY wr.w_refunded_customer_sk
        )
)
GROUP BY fa.ca_city
ORDER BY total_online_sales DESC;
