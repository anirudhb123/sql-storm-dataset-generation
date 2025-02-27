
WITH SalesSummary AS (
    SELECT
        d.d_year,
        c.c_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        d.d_year, c.c_gender
),
AggregateSales AS (
    SELECT
        d_year,
        c_gender,
        total_orders,
        total_profit,
        total_quantity,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_orders DESC) AS orders_rank
    FROM
        SalesSummary
)
SELECT
    d_year,
    c_gender,
    total_orders,
    total_profit,
    total_quantity,
    profit_rank,
    orders_rank
FROM
    AggregateSales
WHERE
    profit_rank <= 5 OR orders_rank <= 5
ORDER BY
    d_year, profit_rank, orders_rank;
