
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS number_of_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT
        cr.sr_customer_sk,
        cr.total_returned_quantity,
        cr.number_of_returns,
        cr.total_returned_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned_amount DESC) AS rn
    FROM
        CustomerReturns cr
    WHERE
        cr.total_returned_quantity > 5
),
ItemStatistics AS (
    SELECT
        ws.ws_item_sk,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS total_sales_count,
        SUM(CASE WHEN ws.ws_sales_price > 100 THEN 1 ELSE 0 END) AS high_value_sales
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
FilteredItems AS (
    SELECT
        i.i_item_id,
        is.avg_sales_price,
        is.total_sales_count,
        is.high_value_sales
    FROM
        item i
    JOIN ItemStatistics is ON i.i_item_sk = is.ws_item_sk
    WHERE
        is.avg_sales_price BETWEEN 50 AND 200
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hc.total_returned_quantity, 0) AS returns_quantity,
    COALESCE(hc.number_of_returns, 0) AS returns_count,
    ii.i_item_id,
    ii.avg_sales_price,
    ii.total_sales_count,
    ii.high_value_sales
FROM
    customer c
LEFT JOIN HighReturnCustomers hc ON c.c_customer_sk = hc.sr_customer_sk
JOIN FilteredItems ii ON ii.i_item_id IN (
    SELECT
        DISTINCT wp.wp_url
    FROM
        web_page wp
    WHERE
        wp.wp_creation_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim))
)
WHERE
    hc.rn <= 10
ORDER BY
    returns_quantity DESC, returns_count DESC;
