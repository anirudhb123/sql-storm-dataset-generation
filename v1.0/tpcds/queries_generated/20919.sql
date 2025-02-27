
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    INNER JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_id
),
HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_spent,
        COUNT(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_order_number END) AS frequent_buyers
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING
        total_spent > 1000 OR frequent_buyers > 10
),
CustomerReturns AS (
    SELECT
        wr.refunded_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_returns
    FROM
        web_returns wr
    GROUP BY
        wr.refunded_customer_sk
),
FinalReport AS (
    SELECT
        c.c_customer_id,
        COALESCE(hvc.total_spent, 0) AS total_spent,
        COALESCE(hvc.frequent_buyers, 0) AS total_frequent_buyers,
        COALESCE(cr.return_count, 0) AS total_returns,
        COALESCE(cr.total_returns, 0) AS total_return_amt
    FROM
        customer c
    LEFT JOIN
        HighValueCustomers hvc ON c.c_customer_id = hvc.c_customer_id
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.refunded_customer_sk
)
SELECT
    f.c_customer_id,
    f.total_spent,
    f.total_frequent_buyers,
    f.total_returns,
    f.total_return_amt,
    CASE
        WHEN f.total_spent > 1000 THEN 'VIP'
        WHEN f.total_spent BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_status,
    (CASE WHEN f.total_returns > 0 THEN NULL ELSE 'No Returns' END) AS return_status
FROM
    FinalReport f
ORDER BY
    f.total_spent DESC NULLS LAST;
