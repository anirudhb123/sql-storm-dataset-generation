
WITH RECURSIVE SalesAggregate AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        DATE(DATEADD(DAY, ss_sold_date_sk, '1970-01-01')) AS sales_date
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
TopStores AS (
    SELECT 
        sa.ss_store_sk,
        sa.total_sales,
        row_number() OVER (ORDER BY sa.total_sales DESC) AS sales_rank
    FROM SalesAggregate sa
    WHERE sa.total_sales > 100000
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesAndReturns AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS total_transactions,
        COUNT(DISTINCT cr.return_count) AS total_return_transactions
    FROM customer cs
    LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON cs.c_customer_sk = cr.sr_customer_sk
    GROUP BY cs.c_customer_sk
)
SELECT 
    s.store_name,
    sa.total_sales,
    sa.total_transactions,
    r.total_returns,
    r.total_return_transactions,
    (sa.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
FROM TopStores ts
JOIN SalesAggregate sa ON ts.ss_store_sk = sa.ss_store_sk
JOIN store s ON s.s_store_sk = ts.ss_store_sk
LEFT JOIN SalesAndReturns r ON r.c_customer_sk IN (
    SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = s.s_store_sk
)
WHERE sa.sales_date = CURRENT_DATE 
ORDER BY net_sales DESC
LIMIT 10;
