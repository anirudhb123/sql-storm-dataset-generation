
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws_sold_date_sk, ws_item_sk
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
),
ProductSales AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(sr_return_amt), 0) AS total_store_returns
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY i_item_sk, i_item_desc
)
SELECT 
    ps.i_item_sk,
    ps.i_item_desc,
    ps.total_web_sales,
    ps.total_catalog_sales,
    ps.total_store_sales,
    ar.total_returns,
    ar.total_return_amount,
    COALESCE(ps.total_web_sales + ps.total_catalog_sales + ps.total_store_sales - ar.total_return_amount, 0) AS net_sales,
    (SELECT COUNT(*) FROM SalesCTE WHERE ws_item_sk = ps.i_item_sk AND sales_rank <= 10) AS is_top_selling
FROM ProductSales ps
LEFT JOIN AggregatedReturns ar ON ps.i_item_sk = ar.cr_item_sk
WHERE (ps.total_web_sales > 1000 OR ps.total_catalog_sales > 1000 OR ps.total_store_sales > 1000)
AND (ar.total_returns IS NULL OR ar.total_returns < 5)
ORDER BY net_sales DESC
LIMIT 50;
