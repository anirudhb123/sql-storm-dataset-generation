
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighPerformers AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_net_profit,
        COALESCE(c.cd_gender, 'Unknown') AS gender,
        COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Anonymous') AS customer_name
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c ON c.c_customer_sk = (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = rs.ws_item_sk 
        ORDER BY ws_net_profit DESC 
        LIMIT 1
    )
    WHERE rs.rank <= 10
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    hp.i_item_id,
    hp.i_item_desc,
    hp.total_quantity,
    hp.total_net_profit,
    hr.total_returns,
    hr.total_return_amt,
    CASE 
        WHEN hp.total_net_profit > 10000 THEN 'High Value Item'
        WHEN hp.total_net_profit IS NULL THEN 'No Profit'
        ELSE 'Standard Item'
    END AS item_value_category
FROM HighPerformers hp
LEFT JOIN AggregatedReturns hr ON hp.ws_item_sk = hr.wr_item_sk
ORDER BY hp.total_net_profit DESC, hp.total_quantity DESC;
