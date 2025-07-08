
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_store_sk, ss_item_sk, SUM(ss_net_paid) AS total_sales, 1 AS level
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
    UNION ALL
    SELECT sh.ss_store_sk, sh.ss_item_sk, sh.total_sales + (sh.total_sales * 0.1), sh.level + 1
    FROM SalesHierarchy sh
    WHERE sh.level < 3
), 

MonthlySales AS (
    SELECT 
        d_year,
        EXTRACT(MONTH FROM d_date) AS month,
        SUM(ws_net_paid) AS monthly_sales
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year >= 2022
    GROUP BY d_year, EXTRACT(MONTH FROM d_date)
),

CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),

TotalSales AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS sale_count,
        SUM(ss_net_paid) AS net_sales_total
    FROM store_sales
    GROUP BY ss_store_sk
)

SELECT 
    sh.ss_store_sk,
    sh.total_sales AS sales_with_increase,
    ms.d_year AS sales_year,
    ms.month AS sales_month,
    ms.monthly_sales,
    cr.total_returns,
    cr.return_count
FROM SalesHierarchy sh 
FULL OUTER JOIN MonthlySales ms ON sh.ss_store_sk = ms.d_year 
FULL OUTER JOIN CustomerReturns cr ON cr.sr_customer_sk = sh.ss_store_sk
WHERE (sh.total_sales IS NOT NULL OR ms.monthly_sales IS NOT NULL OR cr.total_returns IS NOT NULL)
ORDER BY sh.ss_store_sk, ms.d_year, ms.month;
