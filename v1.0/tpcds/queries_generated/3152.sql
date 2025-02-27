
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
RecentReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(wr_return_number) AS num_returns
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rws.ws_item_sk,
        COALESCE(r.total_returned, 0) AS total_returned,
        rws.ws_net_profit,
        rws.ws_order_number
    FROM 
        RankedSales rws
    LEFT JOIN 
        RecentReturns r ON rws.ws_item_sk = r.wr_item_sk
    WHERE 
        rws.rnk = 1
)
SELECT 
    sws.ws_item_sk,
    s.item_desc,
    SUM(sws.ws_net_profit) AS total_net_profit,
    AVG(sws.total_returned) AS avg_returns,
    COUNT(DISTINCT sws.ws_order_number) AS total_sales_orders,
    COUNT(DISTINCT CASE WHEN s.ws_net_profit > 0 THEN sws.ws_order_number END) AS profitable_orders
FROM 
    SalesWithReturns sws
JOIN 
    item s ON sws.ws_item_sk = s.i_item_sk
WHERE 
    s.i_current_price > 20.00
GROUP BY 
    sws.ws_item_sk, s.item_desc
HAVING 
    AVG(sws.total_returned) < 5
ORDER BY 
    total_net_profit DESC
LIMIT 10;
