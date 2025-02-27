
WITH RecentSales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        SUM(ws.ws_net_paid - ws.ws_ext_discount_amt) AS net_revenue
    FROM
        web_sales ws
    LEFT JOIN
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        ws.web_site_id
),
CustomerAnalytics AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
FinalReport AS (
    SELECT
        ra.web_site_id,
        ra.total_sales,
        ra.total_orders,
        ra.average_profit,
        ra.total_returns,
        ra.net_revenue,
        ca.c_customer_id,
        ca.cd_gender,
        ca.cd_marital_status,
        ca.cd_education_status,
        ca.total_spent,
        ca.order_count,
        ca.last_purchase_date
    FROM
        RecentSales ra
    JOIN
        CustomerAnalytics ca ON ra.web_site_id = (
            SELECT MAX(web_site_sk) FROM web_site -- Assuming some logic to relate web_site_id
        )
)
SELECT
    *
FROM
    FinalReport
WHERE
    total_sales > 10000
ORDER BY
    total_sales DESC;
