
WITH RankedSales AS (
    SELECT
        w.w_warehouse_name,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        w.w_warehouse_name, i.i_item_id
),
TopSellingItems AS (
    SELECT
        warehouse_name,
        i_item_id,
        total_quantity,
        total_profit
    FROM
        RankedSales
    WHERE
        rank_profit <= 5
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    COALESCE(ws_total.total_sales, 0) AS total_sales,
    COALESCE(cr_total.total_returns, 0) AS total_returns,
    COALESCE(wr_total.total_web_returns, 0) AS total_web_returns,
    (COALESCE(ws_total.total_sales, 0) - COALESCE(cr_total.total_returns, 0) - COALESCE(wr_total.total_web_returns, 0)) AS net_sales
FROM
    customer c
LEFT JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
) ws_total ON c.c_customer_sk = ws_total.ws_bill_customer_sk
LEFT JOIN (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
) cr_total ON c.c_customer_sk = cr_total.sr_customer_sk
LEFT JOIN (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_web_returns
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
) wr_total ON c.c_customer_sk = wr_total.wr_returning_customer_sk
WHERE
    EXISTS (
        SELECT 1
        FROM TopSellingItems tsi
        WHERE tsi.warehouse_name IN (
            SELECT w_warehouse_name
            FROM warehouse
            WHERE w_state = 'CA'
        )
        AND c.c_customer_id = (SELECT c.c_customer_id FROM customer WHERE c.c_customer_sk = c.c_customer_sk LIMIT 1)
    )
ORDER BY
    net_sales DESC;
