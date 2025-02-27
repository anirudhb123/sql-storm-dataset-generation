
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rnk
    FROM 
        web_sales ws
    LEFT JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_gmt_offset IS NOT NULL
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        COUNT(DISTINCT cr.return_order_number) AS unique_returns,
        AVG(cr.return_fee) AS avg_return_fee
    FROM 
        store_returns cr 
    GROUP BY 
        cr.returning_customer_sk
),
NetProfit AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 
    GROUP BY 
        ss.ss_item_sk
),
CombinedData AS (
    SELECT 
        r.web_site_sk,
        r.total_quantity,
        r.total_sales,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.unique_returns, 0) AS unique_returns,
        COALESCE(c.avg_return_fee, 0.00) AS avg_return_fee,
        COALESCE(n.total_net_profit, 0.00) AS total_net_profit
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.web_site_sk = c.returning_customer_sk
    LEFT JOIN 
        NetProfit n ON r.web_site_sk = n.ss_item_sk
)
SELECT 
    web_site_sk,
    total_quantity,
    total_sales,
    total_returns,
    unique_returns,
    avg_return_fee,
    total_net_profit,
    CASE 
        WHEN total_sales = 0 THEN NULL 
        ELSE (total_net_profit / total_sales) 
    END AS profit_margin
FROM 
    CombinedData
WHERE 
    total_quantity > 0
ORDER BY 
    profit_margin DESC 
LIMIT 10;
