
WITH SalesSummary AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        DATE(d.d_date) AS sales_date
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2022
    GROUP BY
        ws.web_site_id, DATE(d.d_date)
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
PromotionsUsed AS (
    SELECT
        ws.ws_order_number,
        COUNT(DISTINCT ws.ws_promo_sk) AS promo_count
    FROM
        web_sales ws
    WHERE
        ws.ws_ext_sales_price > 100
    GROUP BY
        ws.ws_order_number
)
SELECT
    s.web_site_id,
    s.sales_date,
    s.total_sales,
    s.total_orders,
    s.avg_net_paid,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.income_rank,
    pu.promo_count
FROM
    SalesSummary s
JOIN
    CustomerInfo ci ON ci.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.ws_sold_date_sk = (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = s.sales_date)
        LIMIT 1
    )
LEFT JOIN
    PromotionsUsed pu ON pu.ws_order_number = s.total_orders
WHERE
    (ci.cd_marital_status = 'M' AND ci.cd_purchase_estimate > 5000)
    OR (ci.cd_gender = 'F' AND pu.promo_count > 1)
ORDER BY
    s.total_sales DESC, income_rank
LIMIT 100;
