
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        s_store_sk
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        r.total_sales,
        r.total_transactions
    FROM 
        store s
    JOIN 
        RankedSales r ON s.s_store_sk = r.s_store_sk
    WHERE 
        r.sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
    GROUP BY 
        sr_store_sk
)
SELECT 
    ts.s_store_name,
    ts.total_sales,
    ts.total_transactions,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    (ts.total_sales - COALESCE(cr.total_return_amount, 0)) AS net_sales
FROM 
    TopStores ts
LEFT JOIN 
    CustomerReturns cr ON ts.s_store_sk = cr.sr_store_sk
ORDER BY 
    net_sales DESC;
