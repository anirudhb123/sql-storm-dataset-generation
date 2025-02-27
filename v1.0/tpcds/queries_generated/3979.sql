
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM web_sales ws
),
FilteredReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_returned
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
    GROUP BY cr.returning_customer_sk, cr.cr_item_sk
),
TotalSales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023)
    GROUP BY ss.ss_customer_sk, ss.ss_item_sk
),
SalesWithReturns AS (
    SELECT 
        t.total_sales,
        fr.total_returned,
        fr.returning_customer_sk,
        t.ss_item_sk,
        CASE 
            WHEN fr.total_returned IS NULL THEN t.total_sales
            ELSE t.total_sales - fr.total_returned
        END AS net_sales
    FROM TotalSales t
    LEFT JOIN FilteredReturns fr 
    ON t.ss_item_sk = fr.cr_item_sk AND t.ss_customer_sk = fr.returning_customer_sk
)
SELECT 
    r.web_site_sk,
    SUM(swr.net_sales) AS adjusted_sales,
    AVG(swr.net_sales) AS avg_sales,
    COUNT(DISTINCT swr.ss_item_sk) AS distinct_items
FROM SalesWithReturns swr
JOIN RankedSales r ON swr.ss_item_sk = r.ws_order_number
WHERE r.rank_profit <= 10
GROUP BY r.web_site_sk
HAVING SUM(swr.net_sales) > 1000
ORDER BY adjusted_sales DESC;
