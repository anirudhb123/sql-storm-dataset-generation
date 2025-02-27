
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales AS ws
    JOIN
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_id
),
CustomerProfits AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS customer_total_net_profit
    FROM
        customer AS c
    LEFT JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        cp.c_customer_id,
        cp.orders_count,
        cp.customer_total_net_profit,
        RANK() OVER (ORDER BY cp.customer_total_net_profit DESC) AS customer_rank
    FROM
        CustomerProfits cp
    WHERE
        cp.customer_total_net_profit > 0
)
SELECT
    sd.web_site_id,
    sd.total_quantity,
    sd.total_net_profit,
    tc.c_customer_id,
    tc.orders_count,
    tc.customer_total_net_profit
FROM
    SalesData sd
LEFT JOIN
    TopCustomers tc ON tc.orders_count >= 5
WHERE
    sd.profit_rank <= 10
ORDER BY
    sd.total_net_profit DESC, sd.web_site_id;
