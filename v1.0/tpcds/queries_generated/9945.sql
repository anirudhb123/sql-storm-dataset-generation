
WITH RankedSales AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND cd.cd_purchase_estimate > 1000
    GROUP BY
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT
        r.bill_customer_sk,
        r.total_profit,
        r.order_count
    FROM
        RankedSales r
    WHERE
        r.rank <= 10
)
SELECT
    c.first_name,
    c.last_name,
    c.email_address,
    tc.total_profit,
    tc.order_count
FROM
    TopCustomers tc
JOIN
    customer c ON tc.bill_customer_sk = c.customer_sk
ORDER BY
    tc.total_profit DESC;
