
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_store_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS average_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk, sr_store_sk
),
ItemPerformance AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighReturnItems AS (
    SELECT 
        cr.sr_item_sk,
        cr.return_count,
        ip.total_sold,
        ip.total_net_profit,
        COALESCE(ip.total_net_profit / NULLIF(ip.total_sold, 0), 0) AS profit_per_item
    FROM 
        CustomerReturns cr
    JOIN 
        ItemPerformance ip ON cr.sr_item_sk = ip.ws_item_sk
    WHERE 
        cr.return_count > 5
),
StoreComparison AS (
    SELECT 
        ws_store_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_store_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(hr.return_count, 0) AS total_returns,
    hr.total_sold,
    hr.total_net_profit,
    hr.profit_per_item,
    sc.total_profit,
    sc.order_count,
    CASE 
        WHEN sc.rank_profit <= 5 THEN 'Top Performers'
        ELSE 'Regular Performers'
    END AS performance_category
FROM 
    item i
LEFT JOIN 
    HighReturnItems hr ON i.i_item_sk = hr.sr_item_sk
JOIN 
    StoreComparison sc ON hr.sr_store_sk = sc.ws_store_sk
WHERE 
    hr.profit_per_item > (SELECT AVG(profit_per_item) FROM HighReturnItems)
ORDER BY 
    total_returns DESC, 
    total_net_profit DESC;
