
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        s_store_sk
),
HighPerformingStores AS (
    SELECT 
        s_store_sk,
        store_name,
        total_sales,
        total_transactions
    FROM 
        SalesCTE
    JOIN store ON SalesCTE.s_store_sk = store.s_store_sk
    WHERE 
        rank <= 10
),
CustomerReturnStats AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023) )
    GROUP BY 
        sr_store_sk
)
SELECT 
    hps.store_name,
    hps.total_sales,
    hps.total_transactions,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    (hps.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales
FROM 
    HighPerformingStores hps
LEFT JOIN 
    CustomerReturnStats cr ON hps.s_store_sk = cr.sr_store_sk
ORDER BY 
    net_sales DESC;
