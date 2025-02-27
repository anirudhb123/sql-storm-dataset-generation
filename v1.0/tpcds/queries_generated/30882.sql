
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_sold_date_sk
),
TopStores AS (
    SELECT 
        ss_store_sk,
        total_net_profit
    FROM 
        SalesCTE
    WHERE 
        profit_rank <= 10
),
CustomerReturns AS (
    SELECT 
        s_store_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    JOIN 
        store s ON sr.s_store_sk = s.s_store_sk
    GROUP BY 
        s_store_sk
),
SalesWithReturns AS (
    SELECT 
        ts.ss_store_sk,
        ts.total_net_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (ts.total_net_profit - COALESCE(cr.total_returns, 0)) AS net_profit_after_returns
    FROM 
        TopStores ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ss_store_sk = cr.s_store_sk
),
FinalResult AS (
    SELECT 
        swr.ss_store_sk,
        swr.total_net_profit,
        swr.total_returns,
        swr.net_profit_after_returns,
        CASE 
            WHEN swr.net_profit_after_returns < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status
    FROM 
        SalesWithReturns swr
)
SELECT 
    s.s_store_name,
    f.total_net_profit,
    f.total_returns,
    f.net_profit_after_returns,
    f.profit_status,
    DATE_FORMAT(dd.d_date, '%Y-%m-%d') AS report_date
FROM 
    FinalResult f
JOIN 
    store s ON f.ss_store_sk = s.s_store_sk
CROSS JOIN 
    (SELECT d_date FROM date_dim WHERE d_year = 2023 LIMIT 1) dd
ORDER BY 
    f.net_profit_after_returns DESC;
