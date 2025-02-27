
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        ws.ws_order_number, 
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) as rank_profit,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
        AND ws.ws_net_profit IS NOT NULL
),
TopSales AS (
    SELECT 
        *,
        CASE 
            WHEN rank_profit <= 5 THEN 'Top 5 Profits'
            ELSE 'Other Profits' 
        END as sale_category
    FROM 
        RankedSales
),
AggregatedReturns AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) as total_returns, 
        COUNT(DISTINCT wr.wr_order_number) as return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ProfitableItems AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales_profit,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns_amt,
        CASE 
            WHEN COALESCE(SUM(sr.sr_return_amt), 0) = 0 THEN 0
            ELSE ROUND((COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(sr.sr_return_amt), 0)) / COALESCE(SUM(ws.ws_net_profit), 0) * 100, 2) 
        END AS profit_margin
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    tsi.web_site_id,
    tsi.ws_order_number,
    tsi.sale_category,
    pi.i_item_id,
    pi.total_sales_profit,
    pi.total_returns_amt,
    pi.profit_margin
FROM 
    TopSales tsi
JOIN 
    ProfitableItems pi ON tsi.web_site_id = pi.i_item_id
WHERE 
    (tsi.sale_category = 'Top 5 Profits' OR pi.profit_margin > 30)
ORDER BY 
    tsi.web_site_id, pi.total_sales_profit DESC;
