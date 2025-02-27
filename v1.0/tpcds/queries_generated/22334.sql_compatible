
WITH RankedReturns AS (
    SELECT
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        DENSE_RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rank
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk, cr_item_sk
),
HighReturnItems AS (
    SELECT
        r.cr_item_sk,
        r.total_returned,
        r.rank,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_formulation, ''), 'N/A') AS item_formulation
    FROM
        RankedReturns r
    JOIN
        item i ON r.cr_item_sk = i.i_item_sk
    WHERE
        r.rank <= 3
),
CustomerDemographicsWithIncome AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ib.ib_income_band_sk
    FROM
        customer_demographics cd
    LEFT JOIN
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalReport AS (
    SELECT
        c.c_customer_id,
        cdw.cd_gender,
        cdw.cd_marital_status,
        SUM(hri.total_returned) AS total_returned_items,
        COUNT(DISTINCT hri.cr_item_sk) AS distinct_returned_items,
        STRING_AGG(DISTINCT hri.item_formulation, ', ') AS formulations,
        COUNT(*) FILTER (WHERE hri.total_returned > 1) AS multiple_returns
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        CustomerDemographicsWithIncome cdw ON c.c_current_cdemo_sk = cdw.cd_demo_sk
    LEFT JOIN
        HighReturnItems hri ON c.c_customer_sk = hri.cr_returning_customer_sk
    GROUP BY
        c.c_customer_id, cdw.cd_gender, cdw.cd_marital_status
    HAVING
        SUM(hri.total_returned) IS NOT NULL
        AND COUNT(DISTINCT hri.cr_item_sk) > 0
)
SELECT
    CASE
        WHEN total_returned_items IS NULL THEN 'No returns'
        WHEN total_returned_items > 10 THEN 'Frequent Returns'
        ELSE 'Occasional Returns'
    END AS return_behavior,
    cd_gender,
    cd_marital_status,
    total_returned_items,
    distinct_returned_items,
    formulations,
    multiple_returns
FROM
    FinalReport
ORDER BY
    total_returned_items DESC NULLS LAST;
