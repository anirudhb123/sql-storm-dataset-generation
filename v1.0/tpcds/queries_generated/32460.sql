
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        0 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT c_customer_sk FROM store_sales)

    UNION ALL

    SELECT 
        sr_returning_customer_sk, 
        c_first_name, 
        c_last_name, 
        ch.level + 1
    FROM store_returns sr
    JOIN customer c ON sr_returning_customer_sk = c.c_customer_sk
    JOIN CustomerHierarchy ch ON sr.sr_refunded_customer_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        COUNT(DISTINCT CASE WHEN ws.ws_quantity IS NULL THEN 1 END) AS null_quantity_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_net_profit,
        sd.num_orders,
        LEAD(sd.total_net_profit) OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.ws_sold_date_sk) AS next_net_profit
    FROM SalesData sd
    WHERE sd.total_net_profit > (SELECT AVG(total_net_profit) FROM SalesData)
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    fs.ws_item_sk,
    fs.total_net_profit,
    fs.num_orders,
    fs.next_net_profit,
    COALESCE(fs.next_net_profit - fs.total_net_profit, 0) AS profit_change,
    CASE 
        WHEN fs.total_net_profit IS NULL THEN 'No sales'
        WHEN fs.total_net_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM FilteredSales fs
JOIN CustomerHierarchy ch ON ch.c_customer_sk IN (
    SELECT DISTINCT sr_refunded_customer_sk 
    FROM store_returns sr
    WHERE sr.sr_item_sk = fs.ws_item_sk
)
ORDER BY fs.total_net_profit DESC
LIMIT 10;
