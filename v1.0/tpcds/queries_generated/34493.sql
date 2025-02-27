
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY ws_item_sk
), item_info AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_returns,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_store_returns
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
), sales_summary AS (
    SELECT 
        ii.i_item_sk,
        ii.i_item_desc,
        ii.total_catalog_sales,
        ii.total_store_sales,
        ss.total_sold,
        ss.total_sales,
        (COALESCE(ii.total_catalog_sales, 0) + COALESCE(ii.total_store_sales, 0) - COALESCE(ii.total_catalog_returns, 0) - COALESCE(ii.total_store_returns, 0)) AS net_sales
    FROM item_info ii
    LEFT JOIN sales_cte ss ON ii.i_item_sk = ss.ws_item_sk
)
SELECT 
    s.i_item_sk,
    s.i_item_desc,
    s.total_catalog_sales,
    s.total_store_sales,
    s.total_sold,
    s.total_sales,
    s.net_sales,
    COALESCE(NULLIF(s.net_sales, 0), -1) AS final_net_sales,
    CASE 
        WHEN s.net_sales > 10000 THEN 'High'
        WHEN s.net_sales BETWEEN 1000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM sales_summary s
WHERE s.net_sales IS NOT NULL
ORDER BY final_net_sales DESC
LIMIT 50;
