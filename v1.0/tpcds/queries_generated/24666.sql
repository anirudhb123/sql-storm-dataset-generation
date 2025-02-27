
WITH CustomerReturnStats AS (
    SELECT
        c.c_customer_id,
        SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END) AS total_returns,
        AVG(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE NULL END) AS avg_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS unique_return_count,
        COUNT(DISTINCT sr_reason_sk) FILTER (WHERE sr_reason_sk IS NOT NULL) AS unique_reasons_count
    FROM
        customer c
    LEFT OUTER JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id
),
PromotionUsage AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_promo_sk) AS promo_count,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM
        web_sales
    WHERE
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 365 FROM date_dim)
    GROUP BY
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_credit_rating,
        COUNT(c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.education_status LIKE '%Bachelor%' OR cd.education_status LIKE '%Master%'
    GROUP BY
        cd_credit_rating
),
FinalReport AS (
    SELECT
        crs.c_customer_id,
        crs.total_returns,
        crs.avg_return_quantity,
        crs.unique_return_count,
        crs.unique_reasons_count,
        COALESCE(pu.promo_count, 0) AS promo_count,
        pu.total_spent,
        dem.customer_count
    FROM
        CustomerReturnStats crs
    LEFT JOIN PromotionUsage pu ON crs.c_customer_id = pu.ws_bill_customer_sk
    LEFT JOIN CustomerDemographics dem ON (SELECT COUNT(1) FROM customer WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_credit_rating > 'B')) > 10
)
SELECT
    f.c_customer_id,
    f.total_returns,
    f.avg_return_quantity,
    f.unique_return_count,
    f.unique_reasons_count,
    f.promo_count,
    f.total_spent,
    CASE
        WHEN f.customer_count IS NULL THEN 'Unknown'
        WHEN f.customer_count > 10 THEN 'Frequent'
        ELSE 'Infrequent'
    END AS customer_category
FROM
    FinalReport f
ORDER BY
    f.total_returns DESC, f.total_spent DESC
LIMIT 100;
