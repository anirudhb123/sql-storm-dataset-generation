
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS hierarchy_level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
ItemSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales_quantity, SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT i.i_item_sk, i.i_item_desc, is.total_sales_quantity, is.total_net_profit,
           RANK() OVER (ORDER BY is.total_net_profit DESC) AS rank
    FROM item i
    JOIN ItemSales is ON i.i_item_sk = is.ws_item_sk
    WHERE is.total_sales_quantity > 0
),
HighValueCustomers AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
           COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
           SUM(is.total_net_profit) AS total_profit
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    LEFT JOIN ItemSales is ON is.ws_item_sk IN (
        SELECT i.i_item_sk FROM item i WHERE i.i_item_sk IN (
            SELECT ti.i_item_sk FROM TopItems ti WHERE ti.rank <= 5
        )
    )
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.total_customers,
    hvc.total_profit,
    COALESCE(SUM(tp.total_net_profit) OVER (PARTITION BY hvc.cd_marital_status), 0) AS total_profit_by_marital_status
FROM HighValueCustomers hvc 
LEFT JOIN TopItems tp ON tp.total_net_profit > 0
WHERE hvc.total_profit > 1000
ORDER BY hvc.total_profit DESC
LIMIT 10;
