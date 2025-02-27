
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_income_band_sk,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           0 AS Level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_income_band_sk,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ch.Level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_hdemo_sk
), 
SalesData AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
TopItems AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        sd.avg_sales_price,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM SalesData sd
)
SELECT
    ch.c_customer_id,
    ch.cd_gender,
    ch.cd_income_band_sk,
    ti.total_quantity,
    ti.total_net_profit,
    ti.avg_sales_price,
    CASE 
        WHEN ch.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN ch.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CustomerHierarchy ch
LEFT JOIN TopItems ti ON ch.c_customer_sk = ti.cs_item_sk
WHERE ch.Level = 0 AND ti.profit_rank <= 10
ORDER BY ti.total_net_profit DESC, ch.c_customer_id;
