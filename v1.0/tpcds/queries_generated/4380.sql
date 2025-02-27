
WITH RankedReturns AS (
    SELECT
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT
        rr.returning_customer_sk,
        rr.total_returned_quantity,
        rr.total_returns,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        RankedReturns rr
    JOIN customer c ON rr.returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        rr.rn <= 10
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    hrc.returning_customer_sk,
    hrc.total_returned_quantity,
    hrc.total_returns,
    sd.total_spent,
    sd.total_orders,
    COALESCE((SELECT ib.ib_income_band_sk FROM household_demographics hd JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk WHERE hd.hd_demo_sk = hrc.returning_customer_sk), -1) AS income_band
FROM
    HighReturnCustomers hrc
LEFT JOIN SalesData sd ON hrc.returning_customer_sk = sd.ws_bill_customer_sk
WHERE
    (hrc.marital_status = 'Single' AND sd.total_spent > 1000)
    OR (hrc.marital_status = 'Married' AND sd.total_spent > 500)
ORDER BY
    hrc.total_returned_quantity DESC, sd.total_spent DESC
LIMIT 100;
