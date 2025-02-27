
WITH CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr.return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.returning_customer_sk) AS return_count
    FROM
        catalog_returns cr
    GROUP BY
        cr.returning_customer_sk
),
StoreSalesSummary AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 2458210 AND 2458240
    GROUP BY
        ss_store_sk
),
SalesCustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_web_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ReturnStatistics AS (
    SELECT
        cr.returning_cdemo_sk,
        SUM(cr.return_amount) AS total_return,
        COUNT(cr.returning_cdemo_sk) AS return_count
    FROM
        catalog_returns cr
    GROUP BY
        cr.returning_cdemo_sk
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(crs.total_return, 0) AS total_returns,
    COALESCE(sss.total_sales, 0) AS total_sales,
    CASE
        WHEN s.total_transactions > 0 THEN (COALESCE(crs.total_return, 0) / s.total_transactions)
        ELSE 0
    END AS return_rate
FROM
    customer c
LEFT JOIN
    CustomerReturns crs ON c.c_customer_sk = crs.returning_customer_sk
LEFT JOIN
    StoreSalesSummary sss ON sss.ss_store_sk = c.c_current_addr_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    ReturnStatistics crs ON crs.returning_cdemo_sk = cd.cd_demo_sk
WHERE
    cd.cd_gender IS NOT NULL
ORDER BY
    return_rate DESC
LIMIT 100;
