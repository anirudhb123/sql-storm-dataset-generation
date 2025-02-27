
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        1 AS level
    FROM store_sales
    GROUP BY ss_store_sk

    UNION ALL

    SELECT 
        s.ss_store_sk,
        SUM(s.ss_net_paid),
        COUNT(s.ss_ticket_number),
        cte.level + 1
    FROM store_sales s
    JOIN SalesCTE cte ON s.ss_store_sk = cte.ss_store_sk
    WHERE cte.level < 5
    GROUP BY s.ss_store_sk, cte.level
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_store_sk
),
SalesAndReturns AS (
    SELECT 
        s.ss_store_sk,
        COALESCE(cte.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        cte.total_transactions,
        (COALESCE(cte.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        (SELECT DISTINCT ss_store_sk FROM store_sales) s
    LEFT JOIN SalesCTE cte ON s.ss_store_sk = cte.ss_store_sk
    LEFT JOIN CustomerReturns r ON s.ss_store_sk = r.sr_store_sk
),
AverageSales AS (
    SELECT 
        sa.ss_store_sk,
        AVG(sa.net_sales) OVER (PARTITION BY sa.ss_store_sk ORDER BY sa.total_transactions DESC ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS avg_net_sales,
        sa.total_transactions
    FROM 
        SalesAndReturns sa
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(a.avg_net_sales, 0) AS average_net_sales,
    CASE 
        WHEN a.avg_net_sales IS NULL THEN 'No Sales'
        WHEN a.avg_net_sales >= 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value
FROM customer c
LEFT JOIN AverageSales a ON c.c_customer_sk = a.ss_store_sk 
WHERE c.c_birth_year < 1980
ORDER BY average_net_sales DESC
FETCH FIRST 10 ROWS ONLY;
