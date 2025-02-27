
WITH SalesSummary AS (
    SELECT
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_list_price) AS avg_list_price
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        c.c_customer_id
),
DemographicAnalysis AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_sales_by_demographics
    FROM
        SalesSummary ss
    JOIN
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
),
FinalReport AS (
    SELECT
        da.cd_gender,
        da.cd_marital_status,
        da.total_sales_by_demographics,
        ROW_NUMBER() OVER (PARTITION BY da.cd_gender ORDER BY da.total_sales_by_demographics DESC) AS sales_rank
    FROM
        DemographicAnalysis da
)
SELECT
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_sales_by_demographics
FROM
    FinalReport fr
WHERE
    fr.sales_rank <= 10
ORDER BY
    fr.cd_gender,
    fr.total_sales_by_demographics DESC;
