
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_paid IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        MAX(ws_net_paid) AS max_order_value,
        MIN(ws_net_paid) AS min_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_cdemo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
)
SELECT 
    cd.demo_sk,
    cd.gender,
    cd.marital_status,
    cs.total_orders,
    cs.total_spent,
    cs.max_order_value,
    cs.min_order_value
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM CustomerDemographics WHERE cd_gender = 'F')
    OR 
    cd.gender IS NULL
    OR 
    EXISTS (
        SELECT 1 
        FROM RankedSales rs 
        WHERE rs.ws_item_sk IN (
            SELECT hr_item_sk 
            FROM (SELECT LAG(ws_net_paid) OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS previous_value,
                         ws_net_paid AS current_value,
                         ws_item_sk 
                  FROM web_sales) AS t
            WHERE current_value > 2 * COALESCE(previous_value, 0)
        )
        AND rs.rank <= 5
    )
ORDER BY 
    cd.gender ASC, cs.total_spent DESC
LIMIT 100;
