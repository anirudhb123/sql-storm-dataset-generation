
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        1 AS level
    FROM item i
    WHERE i.i_item_sk IS NOT NULL
    UNION ALL
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        CONCATih.i_item_desc, ' - Child') AS i_item_desc,
        i.i_current_price * 0.9, -- applying a discount for illustration
        ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk + 1
    WHERE ih.level < 5
), 
SalesSummary AS (
    SELECT
        ws.ws_sold_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ARRAY_AGG(DISTINCT ib.ib_income_band_sk) AS income_bands
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_orders,
    ss.total_sales,
    ss.avg_order_value,
    ih.i_item_desc,
    ih.i_current_price
FROM CustomerInfo ci
JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_sold_date_sk
LEFT JOIN ItemHierarchy ih ON (ih.i_item_sk % 7 = 0) -- Example of a complicated predicate
WHERE (ci.cd_gender IS NOT NULL OR ci.cd_marital_status IS NULL) -- NULL logic
  AND ss.total_orders > 10
ORDER BY total_sales DESC
LIMIT 100;
