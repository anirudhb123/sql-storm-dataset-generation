
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws.order_number,
        ws.item_sk,
        ws.quantity,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.order_number ORDER BY ws.item_sk) AS rn
    FROM
        web_sales ws
    WHERE
        ws.sold_date_sk BETWEEN 2400 AND 2500
    UNION ALL
    SELECT
        cs.order_number,
        cs.item_sk,
        cs.quantity,
        cs.net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.order_number ORDER BY cs.item_sk) AS rn
    FROM
        catalog_sales cs
    WHERE
        cs.sold_date_sk BETWEEN 2400 AND 2500
),
AggregatedSales AS (
    SELECT
        c.c_customer_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_profit) AS total_net_profit
    FROM
        SalesCTE s
    JOIN
        customer c ON c.c_customer_sk = COALESCE(s.quantity, 0) -- Handling NULL values
    GROUP BY
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT
        cd.gender,
        cd.marital_status,
        COUNT(cd.cd_demo_sk) AS demo_count
    FROM
        customer_demographics cd
    WHERE
        cd.cd_marital_status IN ('M', 'S')
    GROUP BY
        cd.gender, cd.marital_status
)
SELECT
    COALESCE(a.c_customer_id, 'Unknown') AS customer_id,
    COALESCE(a.total_quantity, 0) AS total_quantity,
    COALESCE(a.total_net_profit, 0) AS total_net_profit,
    cd.gender,
    cd.marital_status,
    cd.demo_count
FROM
    AggregatedSales a
FULL OUTER JOIN CustomerDemographics cd ON a.total_quantity > 0 AND cd.demo_count > 0
WHERE
    (a.total_net_profit IS NOT NULL OR cd.demo_count > 50) -- Complex condition with NULL logic
ORDER BY
    total_net_profit DESC,
    customer_id;
