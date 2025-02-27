
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        MIN(total_sales) AS min_sales,
        MAX(total_sales) AS max_sales
    FROM SalesData
),
HighValueCustomers AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS high_value_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd.cd_purchase_estimate > (
        SELECT avg_sales FROM AverageSales
    )
    GROUP BY cd.cd_gender
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    c.city,
    c.state,
    hvc.high_value_count,
    hvc.avg_purchase_estimate,
    ROW_NUMBER() OVER (PARTITION BY hvc.cd_gender ORDER BY hvc.high_value_count DESC) AS gender_rank
FROM CustomerHierarchy ch
LEFT JOIN customer_address ca ON ch.c_customer_sk = ca.ca_address_sk
LEFT JOIN HighValueCustomers hvc ON ch.c_current_cdemo_sk = hvc.cd_demo_sk
WHERE ca.ca_country = 'USA' AND (ca.ca_state IN ('CA', 'NY') OR hvc.high_value_count IS NULL)
ORDER BY hvc.high_value_count DESC, gender_rank;
