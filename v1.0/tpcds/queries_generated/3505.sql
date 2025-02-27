
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sales_price > 0
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(wr_return_number) AS return_count
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.return_count, 0) AS return_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE
        cd.cd_purchase_estimate > 1000
)
SELECT
    hv.*,
    CONCAT(hv.c_first_name, ' ', hv.c_last_name) AS full_name,
    CASE
        WHEN hv.total_return_amt IS NULL OR hv.total_return_amt = 0 THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM
    HighValueCustomers hv
WHERE
    hv.return_count > (
        SELECT AVG(return_count)
        FROM CustomerReturns
    )
ORDER BY
    hv.c_last_name,
    hv.c_first_name
LIMIT 100;
