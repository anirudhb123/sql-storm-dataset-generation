
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT
        COALESCE(ws.ws_web_page_sk, cs.cs_call_center_sk) AS source_id,
        SUM(ws.ws_net_profit) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_sales_count
    FROM
        web_sales ws
    FULL OUTER JOIN
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    GROUP BY
        COALESCE(ws.ws_web_page_sk, cs.cs_call_center_sk)
),
IncomeStatistics AS (
    SELECT
        hd.hd_income_band_sk,
        AVG(cd.cd_purchase_estimate) AS average_purchase,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        COUNT(*) AS total_count
    FROM
        household_demographics hd
    JOIN
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY
        hd.hd_income_band_sk
)
SELECT
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    ss.source_id,
    ss.total_web_sales,
    ss.web_sales_count,
    is.avg_purchase,
    is.married_count,
    is.total_count,
    CASE 
        WHEN rc.gender_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_rank_category
FROM
    RankedCustomers rc
LEFT JOIN
    SalesData ss ON rc.c_customer_sk = ss.source_id
LEFT JOIN
    IncomeStatistics is ON rc.c_current_cdemo_sk = is.hd_income_band_sk
WHERE
    (ss.total_web_sales IS NULL OR ss.total_web_sales < 1000) 
    AND (ss.web_sales_count > 5 OR ss.web_sales_count IS NULL)
ORDER BY
    rc.cd_purchase_estimate DESC,
    is.average_purchase ASC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
