
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_month, c_birth_year, 
           c_current_cdemo_sk
    FROM customer
    WHERE c_birth_month IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year, 
           c.c_current_cdemo_sk
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE c.c_customer_sk <> ch.c_customer_sk
),
SalesSummary AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month BETWEEN 1 AND 6
    GROUP BY ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT cd.cd_gender, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
           SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
           SUM(CASE WHEN cd.cd_education_status = 'Bachelor' THEN 1 ELSE 0 END) AS bachelor_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
ShippingDetails AS (
    SELECT sm.sm_ship_mode_id, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
)
SELECT ch.c_first_name, 
       ch.c_last_name, 
       ch.c_birth_month, 
       ch.c_birth_year, 
       ss.total_quantity, 
       ss.total_sales, 
       cd.cd_gender, 
       cd.customer_count, 
       sd.order_count, 
       sd.total_ship_cost
FROM CustomerHierarchy ch
JOIN SalesSummary ss ON ch.c_current_cdemo_sk = ss.ws_item_sk
JOIN CustomerDemographics cd ON cd.cd_gender IS NOT NULL
LEFT JOIN ShippingDetails sd ON ss.ws_item_sk = sd.sm_ship_mode_id
WHERE ss.rank <= 10
ORDER BY ch.c_birth_month ASC, ss.total_sales DESC;
