
WITH RECURSIVE CustomerRevenue AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_revenue,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        customer c
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
    HAVING
        total_revenue > 1000
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
AggregateDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.return_count) AS total_returns
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
    HAVING 
        total_returns > 5
)
SELECT
    cr.c_customer_sk,
    cr.total_revenue,
    ad.cd_gender,
    ad.cd_marital_status
FROM
    CustomerRevenue cr
JOIN 
    AggregateDemographics ad ON cr.c_customer_sk IN (
        SELECT
            c.c_customer_sk 
        FROM 
            customer c
        JOIN
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
        WHERE
            ad.cd_gender = cd.cd_gender AND 
            ad.cd_marital_status = cd.cd_marital_status
    )
ORDER BY 
    cr.total_revenue DESC
LIMIT 10;
