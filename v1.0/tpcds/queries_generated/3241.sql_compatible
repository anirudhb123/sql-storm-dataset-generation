
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
WebSalesStats AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    wss.total_orders,
    wss.total_net_profit,
    wss.avg_sales_price,
    CASE 
        WHEN wss.total_net_profit > 1000 THEN 'High Profit'
        WHEN wss.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    cs.male_count,
    cs.female_count,
    cs.avg_purchase_estimate
FROM item i
LEFT JOIN ReturnStats rs ON i.i_item_sk = rs.sr_item_sk
JOIN WebSalesStats wss ON i.i_item_sk = wss.ws_item_sk
LEFT JOIN CustomerStats cs ON cs.c_customer_sk IN (
    SELECT DISTINCT ws_ship_customer_sk 
    FROM web_sales
    WHERE ws_item_sk = i.i_item_sk
)
WHERE i.i_current_price > 20.00
ORDER BY wss.total_net_profit DESC;
