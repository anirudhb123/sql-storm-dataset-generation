
WITH CustomerStats AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_id
),
DemographicAnalysis AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_net_profit) AS avg_net_profit,
        AVG(cs.total_orders) AS avg_orders,
        AVG(cs.distinct_items_purchased) AS avg_distinct_items
    FROM
        CustomerStats cs
    JOIN
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    da.cd_gender,
    da.cd_marital_status,
    da.avg_net_profit,
    da.avg_orders,
    da.avg_distinct_items
FROM
    DemographicAnalysis da
ORDER BY
    da.avg_net_profit DESC, da.cd_gender, da.cd_marital_status;
