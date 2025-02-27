
WITH RECURSIVE customer_return_summary AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(hd.hd_buy_potential, 'Unknown') ORDER BY cd.cd_purchase_estimate DESC) AS potential_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
aggregate_returns AS (
    SELECT
        cds.c_customer_sk,
        cds.c_first_name,
        cds.c_last_name,
        cds.cd_gender,
        cds.cd_marital_status,
        SUM(crs.total_return_quantity) AS total_returned_items,
        SUM(crs.total_return_amount) AS total_returned_amount
    FROM
        customer_details cds
    LEFT JOIN
        customer_return_summary crs ON cds.c_customer_sk = crs.cr_returning_customer_sk
    GROUP BY
        cds.c_customer_sk, cds.c_first_name, cds.c_last_name, cds.cd_gender, cds.cd_marital_status
)
SELECT
    ar.c_customer_sk,
    ar.c_first_name,
    ar.c_last_name,
    ar.cd_gender,
    ar.cd_marital_status,
    ar.total_returned_items,
    ar.total_returned_amount,
    CASE
        WHEN ar.total_returned_amount IS NULL THEN 'No Returns'
        WHEN ar.total_returned_amount > 1000 THEN 'High Value'
        WHEN ar.total_returned_items > 50 THEN 'Frequent Returner'
        ELSE 'Normal'
    END AS return_status
FROM
    aggregate_returns ar
WHERE
    ar.total_returned_items IS NOT NULL
ORDER BY
    ar.total_returned_amount DESC
LIMIT 10;
