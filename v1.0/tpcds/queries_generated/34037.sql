
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ws.ws_sold_date_sk
    FROM web_sales ws
    GROUP BY ws.web_site_sk, ws.web_name, ws.ws_sold_date_sk
    UNION ALL
    SELECT
        sh.web_site_sk,
        sh.web_name,
        sh.total_sales + COUNT(ws.ws_order_number) AS total_sales,
        sh.total_profit + SUM(ws.ws_net_profit) AS total_profit,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN SalesHierarchy sh ON sh.web_site_sk = ws.ws_web_site_sk
    GROUP BY sh.web_site_sk, sh.web_name, sh.ws_sold_date_sk
),
CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesPerformance AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.total_sales,
        ch.total_profit,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM customer c
    LEFT JOIN SalesHierarchy ch ON c.c_customer_sk = ch.web_site_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
)
SELECT
    sp.c_customer_sk,
    sp.c_first_name,
    sp.c_last_name,
    sp.total_sales,
    sp.total_profit,
    CASE
        WHEN sp.total_returns > 0 THEN 'Returned'
        ELSE 'Active'
    END AS customer_status,
    RANK() OVER (PARTITION BY sp.c_customer_sk ORDER BY sp.total_sales DESC) AS sales_rank
FROM SalesPerformance sp
WHERE sp.total_sales IS NOT NULL
ORDER BY sp.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
