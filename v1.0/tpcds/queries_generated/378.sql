
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c.c_customer_sk) AS customer_count
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'S'
    GROUP BY
        cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT
        sd.web_site_id,
        sd.total_net_paid,
        sd.total_orders,
        cd.avg_purchase_estimate,
        cd.customer_count,
        DENSE_RANK() OVER (ORDER BY sd.total_net_paid DESC) AS sales_rank
    FROM
        SalesData sd
    LEFT JOIN
        CustomerDemographics cd ON cd.customer_count > 0
)
SELECT
    sa.web_site_id,
    sa.total_net_paid,
    sa.total_orders,
    COALESCE(sa.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    sa.sales_rank
FROM
    SalesAnalysis sa
WHERE
    (sa.total_orders > 10 OR sa.total_net_paid > 1000)
    AND sa.sales_rank <= 10
ORDER BY
    sa.sales_rank;
