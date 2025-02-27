
WITH TotalSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
HighProfitItems AS (
    SELECT
        T.ws_item_sk,
        T.total_quantity,
        T.total_sales,
        T.total_profit,
        I.i_item_desc,
        C.c_first_name,
        C.c_last_name
    FROM
        TotalSales T
    JOIN
        item I ON T.ws_item_sk = I.i_item_sk
    JOIN
        customer C ON T.total_profit > 1000 AND C.c_customer_sk IN (
            SELECT ws_bill_customer_sk
            FROM web_sales
            WHERE ws_item_sk = T.ws_item_sk
            GROUP BY ws_bill_customer_sk
        )
)
SELECT
    H.ws_item_sk,
    H.total_quantity,
    H.total_sales,
    H.total_profit,
    H.i_item_desc,
    COUNT(H.c_first_name) AS num_customers
FROM
    HighProfitItems H
GROUP BY
    H.ws_item_sk,
    H.total_quantity,
    H.total_sales,
    H.total_profit,
    H.i_item_desc
HAVING
    COUNT(H.c_first_name) > 1
ORDER BY
    H.total_profit DESC
LIMIT 20;
