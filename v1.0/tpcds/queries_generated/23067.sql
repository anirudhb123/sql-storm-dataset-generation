
WITH RankedReturns AS (
    SELECT
        cr.returning_customer_sk,
        cr.returned_date_sk,
        cr.return_quantity,
        RANK() OVER (PARTITION BY cr.returning_customer_sk ORDER BY cr.return_amount DESC) AS rnk
    FROM
        catalog_returns cr
    WHERE
        cr.return_quantity > 0
    AND
        EXISTS (
            SELECT 1
            FROM store s
            WHERE s.s_store_sk = cr.cr_store_sk AND s.s_state = 'CA'
        )
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
PromotionalData AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        promotion p
    JOIN
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        p.p_promo_id, p.p_promo_name
),
FinalResults AS (
    SELECT
        cd.cd_gender,
        SUM(cr.return_quantity) AS total_returns,
        COALESCE(pr.total_quantity, 0) AS total_promotions,
        COUNT(DISTINCT cr.returning_customer_sk) AS unique_customers
    FROM
        RankedReturns cr
    LEFT JOIN
        CustomerDemographics cd ON cr.returning_customer_sk = cd.cd_demo_sk
    LEFT JOIN
        PromotionalData pr ON cd.cd_demo_sk = pr.p_promo_id
    GROUP BY
        cd.cd_gender
)
SELECT
    fr.cd_gender,
    fr.total_returns,
    fr.total_promotions,
    fr.unique_customers,
    CASE
        WHEN fr.total_returns IS NULL THEN 'No Returns'
        WHEN fr.total_promotions > 100 THEN 'High Promotion Activity'
        ELSE 'Regular Returns'
    END AS return_status
FROM
    FinalResults fr
WHERE
    fr.unique_customers > 50
ORDER BY
    fr.total_returns DESC NULLS LAST;
