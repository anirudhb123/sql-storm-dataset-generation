
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating,
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_first_name IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.cd_gender, ch.cd_marital_status, 
           ch.cd_purchase_estimate, ch.cd_credit_rating,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
),
SalesSummary AS (
    SELECT ws_ship_date_sk, SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_ship_date_sk
),
DateCost AS (
    SELECT d.d_date_sk, 
           AVG(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS avg_inventory,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_sales
    FROM date_dim d
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_date_sk
),
FinalReport AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           ch.cd_gender, ch.cd_marital_status, ch.cd_purchase_estimate, 
           ch.cd_credit_rating, ds.avg_inventory, ds.total_sales,
           cs.total_net_profit
    FROM CustomerHierarchy ch
    LEFT JOIN DateCost ds ON ds.d_date_sk = ch.c_customer_sk
    LEFT JOIN SalesSummary cs ON cs.ws_ship_date_sk = ds.d_date_sk
)
SELECT fr.c_customer_sk, fr.c_first_name, fr.c_last_name,
       fr.cd_gender, fr.cd_marital_status, 
       fr.cd_purchase_estimate, fr.cd_credit_rating,
       fr.avg_inventory, fr.total_sales, 
       COALESCE(fr.total_net_profit, 0) AS total_net_profit
FROM FinalReport fr
WHERE fr.cd_purchase_estimate > (
    SELECT AVG(cd_purchase_estimate) 
    FROM customer_demographics 
    WHERE cd_gender = 'M'
) 
AND fr.total_sales > (SELECT COUNT(*) FROM store_sales)
ORDER BY fr.c_customer_sk;
