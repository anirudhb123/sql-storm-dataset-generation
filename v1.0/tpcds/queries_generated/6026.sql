
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY
        ws.ws_sold_date_sk
),

CustomerProfit AS (
    SELECT
        c.c_customer_id,
        SUM(sd.total_profit) AS customer_profit,
        SUM(sd.total_orders) AS customer_orders,
        SUM(sd.total_quantity) AS customer_quantity,
        AVG(sd.avg_sales_price) AS customer_avg_price
    FROM
        SalesData sd
    JOIN
        web_sales ws ON sd.ws_sold_date_sk = ws.ws_sold_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id
)

SELECT
    cp.c_customer_id,
    cp.customer_profit,
    cp.customer_orders,
    cp.customer_quantity,
    cp.customer_avg_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating
FROM
    CustomerProfit cp
JOIN
    customer_demographics cd ON cp.c_customer_id = cd.cd_demo_sk
WHERE
    cp.customer_profit > 1000
ORDER BY
    cp.customer_profit DESC
LIMIT 100;
