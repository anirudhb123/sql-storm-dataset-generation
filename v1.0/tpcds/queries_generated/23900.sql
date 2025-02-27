
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC, ws.ws_sold_time_sk DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_net_profit > 0
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(cd_dep_count, 0) AS dep_count,
        COALESCE(cd_dep_employed_count, 0) AS dep_employed_count,
        COALESCE(cd_dep_college_count, 0) AS dep_college_count
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate IS NOT NULL
),
SalesSummary AS (
    SELECT
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM
        RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    JOIN web_sales ws ON rs.ws_item_sk = ws.ws_item_sk AND rs.rn = 1
    GROUP BY
        i.i_item_id
)
SELECT
    s.i_item_id,
    s.total_orders,
    s.total_net_profit,
    CASE
        WHEN s.total_net_profit IS NULL THEN 'No Profit'
        WHEN s.avg_net_paid IS NOT NULL AND s.avg_net_paid > 100 THEN 'High Value'
        ELSE 'Standard Value'
    END AS value_type
FROM
    SalesSummary s
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk IN (
    SELECT DISTINCT ws.ws_bill_cdemo_sk
    FROM web_sales ws WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE rn = 1)
)
WHERE
    s.total_orders > (
        SELECT AVG(total_orders) FROM (
            SELECT COUNT(DISTINCT ws_order_number) AS total_orders
            FROM web_sales
            GROUP BY ws_item_sk
        ) AS subquery
    )
ORDER BY
    s.total_net_profit DESC NULLS LAST;
