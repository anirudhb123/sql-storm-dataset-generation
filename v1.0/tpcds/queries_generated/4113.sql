
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.net_profit DESC) as profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
HighProfitSales AS (
    SELECT 
        web_site_id,
        SUM(net_profit) as total_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
    GROUP BY 
        web_site_id
),
ReturnStats AS (
    SELECT 
        wr.web_page_sk,
        SUM(wr.return_amt) as total_return_amount,
        COUNT(wr.return_order_number) as return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.web_page_sk
)
SELECT 
    ws.web_site_id,
    hs.total_net_profit,
    rs.total_return_amount,
    rs.return_count
FROM 
    HighProfitSales hs
LEFT JOIN 
    ReturnStats rs ON hs.web_site_id = rs.web_page_sk
JOIN 
    web_site ws ON hs.web_site_id = ws.web_site_id
WHERE 
    hs.total_net_profit > 50000
    AND (rs.total_return_amount IS NULL OR rs.total_return_amount < 1000)
ORDER BY 
    hs.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
