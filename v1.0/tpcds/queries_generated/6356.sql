
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_list_price) AS avg_list_price,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2000000 AND 2001000
    GROUP BY ws_item_sk
),
TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        i.i_item_desc,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.total_quantity,
        sd.total_profit,
        sd.order_count,
        sd.avg_list_price,
        sd.avg_sales_price
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    JOIN customer c ON c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = sd.ws_item_sk)
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE sd.total_profit > 10000
    ORDER BY sd.total_profit DESC
)
SELECT 
    tp.ws_item_sk,
    tp.i_item_desc,
    tp.cd_gender,
    tp.cd_marital_status,
    tp.total_quantity,
    tp.total_profit,
    tp.order_count,
    tp.avg_list_price,
    tp.avg_sales_price
FROM TopProducts tp
WHERE tp.total_quantity > 500
AND tp.order_count > 10
ORDER BY tp.total_profit DESC
LIMIT 10;
