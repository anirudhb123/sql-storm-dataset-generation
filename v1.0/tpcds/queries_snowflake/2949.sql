
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TopItems AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        RankedSales
    WHERE
        rn <= 10
    GROUP BY
        ws_item_sk
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
        AND ws.ws_sales_price IS NOT NULL
    GROUP BY
        c.c_customer_sk
),
FinalResult AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
        SUM(ts.total_profit) AS total_sales_profit
    FROM
        customer_address ca
    JOIN
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    JOIN
        TopItems ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk = c.c_customer_sk)
    GROUP BY
        ca.ca_city, ca.ca_state
)
SELECT
    ca_city,
    ca_state,
    unique_customers,
    total_sales_profit,
    RANK() OVER (ORDER BY total_sales_profit DESC) AS sales_rank
FROM
    FinalResult
WHERE
    unique_customers > 5
ORDER BY
    total_sales_profit DESC;
