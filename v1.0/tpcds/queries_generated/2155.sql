
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
TotalSales AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_profit) AS total_net_profit
    FROM
        store_sales
    GROUP BY
        ss_customer_sk
),
CombinedSales AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        COALESCE(ws.total_net_profit, 0) + COALESCE(ss.total_net_profit, 0) AS combined_net_profit,
        (COALESCE(ws.order_count, 0) + COUNT(ss.ss_ticket_number)) AS total_orders
    FROM
        SalesSummary ws
    FULL OUTER JOIN
        TotalSales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    cs.customer_sk,
    cs.combined_net_profit,
    cs.total_orders
FROM
    RankedCustomers rc
LEFT JOIN
    CombinedSales cs ON rc.c_customer_sk = cs.customer_sk
WHERE
    (rc.rn <= 10 OR cs.combined_net_profit > 1000)
    AND (rc.cd_gender = 'F' OR (rc.cd_marital_status IS NULL))
ORDER BY
    cs.combined_net_profit DESC NULLS LAST;
