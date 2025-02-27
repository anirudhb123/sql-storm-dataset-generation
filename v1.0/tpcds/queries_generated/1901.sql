
WITH customer_return_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT sr.returned_date_sk) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        AVG(sr.return_quantity) AS avg_return_quantity,
        RANK() OVER (ORDER BY SUM(sr.return_amt) DESC) AS return_rank
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk
),
item_refund_stats AS (
    SELECT
        i.i_item_sk,
        COUNT(DISTINCT cr.order_number) AS total_catalog_returns,
        SUM(cr.return_amount) AS total_catalog_return_amount
    FROM
        item i
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY
        i.i_item_sk
),
web_sales_aggregated AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (
            SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023
        )
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(cr.avg_return_quantity, 0) AS avg_return_quantity,
    wb.total_web_profit,
    wb.total_web_orders,
    ir.total_catalog_returns,
    ir.total_catalog_return_amount
FROM
    customer c
LEFT JOIN customer_return_stats cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN web_sales_aggregated wb ON c.c_customer_sk = wb.ws_bill_customer_sk
LEFT JOIN item_refund_stats ir ON ir.i_item_sk IN (
    SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = c.c_customer_sk
)
WHERE
    c.c_birth_year < 1990 AND
    (cr.total_return_amount IS NOT NULL OR wb.total_web_profit IS NOT NULL)
ORDER BY
    cr.total_return_amount DESC NULLS LAST,
    wb.total_web_profit DESC NULLS LAST
LIMIT 100;
