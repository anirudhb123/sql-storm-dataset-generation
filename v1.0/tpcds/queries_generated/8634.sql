
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(tc.c_customer_sk) AS customer_count
    FROM
        TopCustomers tc
    JOIN
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    WHERE
        tc.rank <= 10
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    COALESCE(CAST(SUM(c.total_spent) AS DECIMAL(10, 2)), 0) AS total_revenue
FROM
    CustomerDemographics cd
LEFT JOIN
    TopCustomers c ON cd.customer_count = c.c_customer_sk
GROUP BY
    cd.cd_gender, cd.cd_marital_status
ORDER BY
    total_revenue DESC;
