
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_net_profit,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_orders,
    sd.total_net_profit,
    sd.ws_quantity,
    CASE 
        WHEN sd.total_net_profit IS NULL THEN 'No Profit'
        WHEN sd.total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM SalesData sd
JOIN item i ON sd.ws_item_sk = i.i_item_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = (SELECT MIN(ws.ws_bill_customer_sk) FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk))
WHERE sd.rn = 1
ORDER BY sd.total_net_profit DESC
LIMIT 10

UNION ALL

SELECT 
    i.i_item_id,
    i.i_item_desc,
    NULL AS total_orders,
    NULL AS total_net_profit,
    NULL AS ws_quantity,
    'Excluded' AS profit_status
FROM item i
WHERE i.i_item_sk NOT IN (SELECT ws_item_sk FROM web_sales)
ORDER BY profit_status;
