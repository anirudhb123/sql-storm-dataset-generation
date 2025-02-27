
WITH SalesData AS (
    SELECT
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        cd.gender,
        cd.marital_status,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws.bill_customer_sk, ws.ship_customer_sk, cd.gender, cd.marital_status
),
TopCustomers AS (
    SELECT
        bill_customer_sk,
        total_profit,
        total_orders,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM
        SalesData
)
SELECT
    tc.bill_customer_sk,
    tc.total_profit,
    tc.total_orders,
    c.first_name,
    c.last_name,
    cd.education_status,
    cd.credit_rating,
    ca.city,
    ca.state,
    ca.country
FROM
    TopCustomers tc
JOIN
    customer c ON tc.bill_customer_sk = c.c_customer_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    tc.profit_rank <= 10
ORDER BY
    tc.total_profit DESC;
