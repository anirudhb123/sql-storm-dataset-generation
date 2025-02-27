
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN CustomerHierarchy ch ON ws.ws_bill_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ca.ca_state = 'CA' AND ch.level <= 3
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TotalSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.order_count) AS total_orders,
        SUM(sd.total_profit) AS total_profit
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
),
ItemLookup AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM item i
)
SELECT 
    il.i_item_sk,
    il.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS total_sales_quantity,
    COALESCE(ts.total_orders, 0) AS total_sales_orders,
    COALESCE(ts.total_profit, 0) AS total_sales_profit,
    'Item ID: ' || il.i_item_id || ', Price: ' || il.i_current_price AS item_details
FROM ItemLookup il
LEFT JOIN TotalSales ts ON il.i_item_sk = ts.ws_item_sk
WHERE il.i_current_price IS NOT NULL
ORDER BY total_sales_profit DESC
LIMIT 10;
