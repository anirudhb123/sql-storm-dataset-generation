
WITH RankedSales AS (
    SELECT
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS order_count,
        SUM(ws.net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT
        r.bill_customer_sk,
        r.order_count,
        r.total_profit
    FROM
        RankedSales r
    WHERE
        r.profit_rank <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.dep_count
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
CustomerAddresses AS (
    SELECT
        ca.ca_address_sk,
        ca.city,
        ca.state,
        ca.country
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT
    tc.bill_customer_sk,
    tc.order_count,
    tc.total_profit,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    cd.dep_count,
    ca.city,
    ca.state,
    ca.country
FROM
    TopCustomers tc
JOIN
    CustomerDemographics cd ON tc.bill_customer_sk = cd.cd_demo_sk
JOIN
    CustomerAddresses ca ON tc.bill_customer_sk = ca.ca_address_sk
ORDER BY
    tc.total_profit DESC;
