
WITH RECURSIVE CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    GROUP BY
        cr.returning_customer_sk
    UNION ALL
    SELECT
        r.returning_customer_sk,
        SUM(r.return_quantity) AS total_returned_quantity,
        SUM(r.return_amount) AS total_return_amount
    FROM
        web_returns r
    INNER JOIN
        CustomerReturns c ON r.returning_customer_sk = c.returning_customer_sk
    GROUP BY
        r.returning_customer_sk
),

SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),

CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 0
            ELSE cd.cd_purchase_estimate
        END AS purchase_estimate
    FROM
        customer_demographics cd
),

HighReturnCustomers AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr.total_return_amount) AS total_return_amount
    FROM
        CustomerReturns cr
    WHERE
        cr.total_returned_quantity > 10
    GROUP BY
        cr.returning_customer_sk
)

SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd_income.ib_lower_bound,
    cd_income.ib_upper_bound,
    COALESCE(hrc.total_return_amount, 0) AS return_amount,
    COALESCE(sd.total_sold_quantity, 0) AS sold_quantity,
    COALESCE(sd.total_profit, 0) AS profit
FROM
    customer c
LEFT JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    income_band cd_income ON cd.cd_income_band_sk = cd_income.ib_income_band_sk
LEFT JOIN
    HighReturnCustomers hrc ON c.c_customer_sk = hrc.returning_customer_sk
LEFT JOIN
    SalesData sd ON c.c_customer_sk = sd.ws_item_sk
WHERE
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
AND 
    (cd.cd_purchase_estimate > 500 OR cd.cd_income_band_sk IS NOT NULL)
AND
    (cd.cd_demo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M'))
ORDER BY
    return_amount DESC
LIMIT 100;
