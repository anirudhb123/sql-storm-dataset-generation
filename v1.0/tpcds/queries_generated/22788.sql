
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate,
        SUM(ws.ws_net_profit) OVER (PARTITION BY c.c_customer_sk) AS total_profit
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        (cd.cd_gender IS NOT NULL OR cd.cd_gender IS NULL) AND
        (cd.cd_marital_status IS NOT NULL OR cd.cd_marital_status IS NULL)
),
ActiveCustomers AS (
    SELECT
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.cd_gender,
        rc.rank_by_estimate,
        rc.total_profit,
        MAX(ws.ws_sales_price) as max_sales_price
    FROM
        RankedCustomers rc
    LEFT JOIN
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        rc.rank_by_estimate <= 10 OR rc.total_profit > 1000
    GROUP BY
        rc.c_customer_sk, rc.c_customer_id, rc.cd_gender, rc.rank_by_estimate, rc.total_profit
),
HighValueReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    WHERE
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sr_customer_sk
),
FinalReport AS (
    SELECT
        ac.c_customer_id,
        ac.cd_gender,
        ac.total_profit,
        COALESCE(hv.total_returned, 0) AS total_returned,
        COALESCE(hv.total_return_amount, 0) AS total_return_amount,
        (ac.total_profit - COALESCE(hv.total_return_amount, 0)) AS net_profit_after_returns
    FROM
        ActiveCustomers ac
    LEFT JOIN
        HighValueReturns hv ON ac.c_customer_sk = hv.sr_customer_sk
)
SELECT
    fr.c_customer_id,
    fr.cd_gender,
    fr.total_profit,
    fr.total_returned,
    fr.total_return_amount,
    fr.net_profit_after_returns
FROM
    FinalReport fr
WHERE
    (fr.total_profit - fr.total_return_amount) > 500
ORDER BY
    fr.net_profit_after_returns DESC NULLS LAST
LIMIT 100
UNION ALL
SELECT
    'Summary' AS c_customer_id,
    NULL AS cd_gender,
    SUM(fr.total_profit) AS total_profit,
    SUM(fr.total_returned) AS total_returned,
    SUM(fr.total_return_amount) AS total_return_amount,
    SUM(fr.net_profit_after_returns) AS net_profit_after_returns
FROM
    FinalReport fr
WHERE
    fr.total_profit IS NOT NULL;
