
WITH SalesData AS (
    SELECT
        s.s_store_name,
        c.c_city,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        s.s_store_name, c.c_city
),
RankedSales AS (
    SELECT
        s_store_name,
        c_city,
        total_quantity_sold,
        total_net_profit,
        total_orders,
        RANK() OVER (PARTITION BY c_city ORDER BY total_net_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY c_city ORDER BY total_quantity_sold DESC) AS quantity_rank
    FROM
        SalesData
)
SELECT
    s_store_name,
    c_city,
    total_quantity_sold,
    total_net_profit,
    total_orders,
    profit_rank,
    quantity_rank
FROM
    RankedSales
WHERE
    profit_rank <= 5 OR quantity_rank <= 5
ORDER BY
    c_city, profit_rank, quantity_rank;
