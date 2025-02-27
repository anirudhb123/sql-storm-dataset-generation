
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM store_sales 
    WHERE ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ss_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns 
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_store_sk
),
StoreProfit AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_sales,
        rs.total_net_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_net_loss, 0) AS total_net_loss,
        (rs.total_net_profit - COALESCE(cr.total_net_loss, 0)) AS net_profit_after_returns
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ss_store_sk = cr.sr_store_sk
)
SELECT 
    s.s_store_id,
    sp.total_sales,
    sp.total_returns,
    CASE 
        WHEN sp.net_profit_after_returns < 0 THEN 'Loss' 
        WHEN sp.net_profit_after_returns = 0 THEN 'Break-even' 
        ELSE 'Profit' 
    END AS profit_status,
    sp.net_profit_after_returns AS net_profit_final,
    CASE 
        WHEN sp.total_sales > 1000 THEN ROUND(sp.net_profit_final * 1.1, 2) 
        ELSE ROUND(sp.net_profit_final, 2) 
    END AS adjusted_net_profit
FROM StoreProfit sp
JOIN store s ON sp.ss_store_sk = s.s_store_sk
WHERE sp.net_profit_after_returns IS NOT NULL 
ORDER BY adjusted_net_profit DESC 
LIMIT 10;
