
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459000 AND 2459080
), TopSales AS (
    SELECT 
        r.web_site_sk,
        SUM(r.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT r.ws_order_number) AS total_orders
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 10
    GROUP BY 
        r.web_site_sk
), StoreReturns AS (
    SELECT 
        sr.s_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.s_store_sk
    HAVING 
        COUNT(*) > 0
), StoreDetails AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(sr.total_returns, 0) AS total_returns,
        COALESCE(sr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ts.total_net_profit, 0) AS total_net_profit,
        COALESCE(ts.total_orders, 0) AS total_orders
    FROM 
        store s
    LEFT JOIN 
        StoreReturns sr ON s.s_store_sk = sr.s_store_sk
    LEFT JOIN 
        TopSales ts ON ts.web_site_sk = s.s_store_sk
)
SELECT 
    sd.s_store_name,
    sd.total_returns,
    sd.total_return_amt,
    sd.total_net_profit,
    sd.total_orders,
    CASE 
        WHEN sd.total_orders > 0 THEN 
            ROUND(sd.total_net_profit / NULLIF(sd.total_orders, 0), 2)
        ELSE 0 
    END AS avg_net_profit_per_order
FROM 
    StoreDetails sd
ORDER BY 
    sd.total_net_profit DESC;
