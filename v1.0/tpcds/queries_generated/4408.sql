
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk
),
TopReturnedItems AS (
    SELECT
        rr.sr_item_sk,
        rr.return_count,
        rr.total_return_amt,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price
    FROM RankedReturns rr
    JOIN item i ON rr.sr_item_sk = i.i_item_sk
    WHERE rr.rn <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cu.c_customer_sk,
        CASE 
            WHEN cu.c_birth_month IS NULL THEN 'Unknown'
            ELSE CONCAT(CAST(cu.c_birth_month AS VARCHAR), '-', CAST(cu.c_birth_day AS VARCHAR))
        END AS birth_date
    FROM customer cu
    LEFT JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
    )
    GROUP BY ws.ws_item_sk
)
SELECT
    tri.i_item_id,
    tri.i_item_desc,
    tri.i_current_price,
    tri.return_count,
    tri.total_return_amt,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_sold,
    sd.total_net_paid
FROM TopReturnedItems tri
LEFT JOIN CustomerDemographics cd ON cd.c_customer_sk IN (
    SELECT sr_customer_sk
    FROM store_returns
    WHERE sr_item_sk = tri.sr_item_sk
)
LEFT JOIN SalesData sd ON sd.ws_item_sk = tri.sr_item_sk
WHERE (tri.return_count > 5 OR cd.cd_gender = 'F')
ORDER BY tri.total_return_amt DESC NULLS LAST;
