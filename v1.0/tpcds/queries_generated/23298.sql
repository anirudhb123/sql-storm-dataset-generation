
WITH RankedSales AS (
    SELECT
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM
        web_sales
),
TopItems AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit
    FROM
        RankedSales rs
    WHERE
        rs.rank_profit <= 3
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    WHERE
        sr_returned_date_sk > (
            SELECT
                MAX(d_date_sk) - 30
            FROM
                date_dim
            WHERE
                d_year = 2023
        )
    GROUP BY
        sr_customer_sk
),
JoinResults AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        ti.ws_item_sk,
        ti.ws_quantity,
        ti.ws_net_profit
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    JOIN
        TopItems ti ON ti.ws_quantity > 10
)
SELECT
    jr.c_customer_sk,
    jr.c_first_name,
    jr.c_last_name,
    jr.total_returns,
    COUNT(jr.ws_item_sk) AS item_count,
    SUM(jr.ws_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(jr.ws_net_profit) > 1000 THEN 'High Value'
        WHEN SUM(jr.ws_net_profit) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    JoinResults jr
GROUP BY
    jr.c_customer_sk,
    jr.c_first_name,
    jr.c_last_name,
    jr.total_returns
HAVING
    COUNT(jr.ws_item_sk) > 1
ORDER BY
    total_net_profit DESC NULLS LAST;
