
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq IN (4, 5) 
        )
    GROUP BY 
        s_store_sk, ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        CASE 
            WHEN wr_return_amt < 0 THEN 0 
            ELSE wr_return_amt 
        END AS adjusted_return,
        wr_returning_customer_sk,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk, adjusted_return
),
StoreAddress AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IN ('CA', 'NY')
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(s.total_profit) AS total_profit,
    COALESCE(SUM(cr.return_count), 0) AS total_returns
FROM 
    StoreAddress ca
LEFT JOIN 
    SalesCTE s ON ca.ca_address_sk = s.s_store_sk
LEFT JOIN 
    CustomerReturns cr ON s.s_store_sk = cr.wr_returning_customer_sk 
WHERE 
    s.profit_rank <= 5
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_profit DESC 
FETCH FIRST 10 ROWS ONLY;
