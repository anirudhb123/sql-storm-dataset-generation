
WITH RankedSales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sales_price BETWEEN 10.00 AND 100.00
),
HighValueReturns AS (
    SELECT
        sr_ticket_number,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_ticket_number
    HAVING
        SUM(sr_return_quantity) > 5
),
CustomerWithHighReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned_quantity,
        cr.total_returned_amount
    FROM
        customer c
    JOIN HighValueReturns cr ON c.c_customer_sk = cr.sr_customer_sk
),
ItemStatistics AS (
    SELECT
        i_item_sk,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        AVG(ws_sales_price) AS avg_price,
        MIN(ws_sales_price) AS min_price,
        MAX(ws_sales_price) AS max_price
    FROM
        web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price IS NOT NULL
    GROUP BY
        i_item_sk
)
SELECT
    cwh.c_customer_sk,
    cwh.c_first_name,
    cwh.c_last_name,
    its.i_item_sk,
    its.num_orders,
    its.avg_price,
    its.min_price,
    its.max_price,
    COALESCE(rk.ws_sales_price, 0) AS top_sales_price,
    CASE
        WHEN cwh.total_returned_amount IS NULL THEN 'No Returns'
        ELSE 'Returned: ' || CAST(cwh.total_returned_amount AS varchar)
    END AS return_info
FROM
    CustomerWithHighReturns cwh
LEFT JOIN RankedSales rk ON rk.ws_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = cwh.c_customer_sk)
JOIN ItemStatistics its ON its.i_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cwh.c_customer_sk)
WHERE
    its.num_orders > 2
ORDER BY
    cwh.c_last_name ASC,
    its.avg_price DESC;
