
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id, ws.web_name
),
TopSites AS (
    SELECT 
        web_site_id,
        total_net_profit 
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
),
ReturnedItems AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    s.ss_sold_date_sk,
    s.ss_store_sk,
    SUM(s.ss_net_profit) AS store_net_profit,
    COALESCE(SUM(r.total_returns), 0) AS total_returns,
    COALESCE(SUM(r.total_return_amt), 0) AS total_return_amt,
    CASE 
        WHEN SUM(s.ss_net_profit) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    store_sales s
LEFT JOIN 
    ReturnedItems r ON s.ss_item_sk = r.wr_item_sk
JOIN 
    customer c ON s.ss_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year >= 1980
    AND s.ss_sold_date_sk IN (SELECT DISTINCT dd.d_date_sk 
                               FROM date_dim dd 
                               WHERE dd.d_year = 2023 
                               AND dd.d_moy IN (1, 2, 3)) 
GROUP BY 
    s.ss_sold_date_sk, s.ss_store_sk
HAVING 
    SUM(s.ss_net_profit) > 0
ORDER BY 
    store_net_profit DESC;
