
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT
        c.c_customer_id,
        cr.return_count,
        cr.total_return_amount,
        cr.total_return_quantity
    FROM
        customer c
    JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        cr.return_count > 5
),
TopProducts AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
    ORDER BY
        total_sales DESC
    LIMIT 10
),
UnreturnedProducts AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_count
    FROM
        item i
    LEFT JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN
        web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    WHERE
        wr.wr_item_sk IS NULL
    GROUP BY
        i.i_item_id, i.i_product_name
)
SELECT
    cc.c_customer_id,
    pp.i_product_name,
    pp.total_sales_count,
    cr.total_return_quantity,
    cr.total_return_amount
FROM
    HighReturnCustomers cc
LEFT JOIN
    UnreturnedProducts pp ON pp.total_sales_count > 0
LEFT JOIN
    CustomerReturns cr ON cc.sr_customer_sk = cr.sr_customer_sk
WHERE
    pp.total_sales_count > 0 OR cr.total_return_quantity IS NOT NULL
ORDER BY
    cr.total_return_amount DESC, pp.total_sales_count DESC;
