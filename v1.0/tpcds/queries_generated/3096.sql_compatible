
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
),
FilteredSales AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_net_profit,
        i.i_brand,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    JOIN customer c ON c.c_customer_sk = (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_order_number = r.ws_order_number LIMIT 1)
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE r.rank = 1 AND r.ws_net_profit > 0
),
TotalSales AS (
    SELECT 
        fs.ws_item_sk,
        SUM(fs.ws_quantity) AS total_quantity,
        SUM(fs.ws_net_profit) AS total_profit
    FROM FilteredSales fs
    GROUP BY fs.ws_item_sk
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_profit,
    CASE 
        WHEN t.total_profit > 1000 THEN 'High Profit'
        WHEN t.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers
FROM TotalSales t
LEFT JOIN FilteredSales fs ON t.ws_item_sk = fs.ws_item_sk
LEFT JOIN customer c ON c.c_customer_sk = fs.c_ship_customer_sk
GROUP BY t.ws_item_sk, t.total_quantity, t.total_profit
ORDER BY t.total_profit DESC;
