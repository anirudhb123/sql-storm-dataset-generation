
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk,
        ws_net_profit,
        ws_qty,
        ws_sales_price,
        ws_ext_discount_amt
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
HighProfitSales AS (
    SELECT 
        rh.item_sk,
        rh.order_number,
        rh.net_profit,
        COALESCE(rh.net_profit - (r.ext_discount_amt + rh.net_profit * 0.05), 0) AS adjusted_profit,
        CASE 
            WHEN rh.net_profit < 0 THEN 'Loss'
            WHEN rh.net_profit > 1000 THEN 'High Profit'
            ELSE 'Regular Profit' 
        END AS profit_category
    FROM 
        RankedSales rh
    LEFT JOIN 
        (SELECT 
             ws_item_sk, 
             SUM(ws_ext_discount_amt) AS ext_discount_amt 
         FROM 
             web_sales 
         GROUP BY 
             ws_item_sk) r 
    ON rh.ws_item_sk = r.ws_item_sk
    WHERE 
        rh.rnk <= 5
    ORDER BY 
        rh.net_profit DESC
)
SELECT 
    sa.ws_item_sk,
    SUM(sa.adjusted_profit) AS total_adjusted_profit,
    COUNT(DISTINCT sa.order_number) AS distinct_order_count,
    MAX(CASE WHEN sa.profit_category = 'High Profit' THEN sa.net_profit ELSE NULL END) AS max_high_profit
FROM 
    HighProfitSales sa
GROUP BY 
    sa.ws_item_sk
HAVING 
    SUM(sa.adjusted_profit) > 5000 
    AND COUNT(*) > 10
ORDER BY 
    total_adjusted_profit DESC;
