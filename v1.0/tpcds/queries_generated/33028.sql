
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_bill_customer_sk, 
           ws_ship_date_sk,
           ws_item_sk, 
           ws_net_profit,
           1 AS level
    FROM web_sales 
    WHERE ws_net_profit IS NOT NULL 

    UNION ALL 

    SELECT sh.ws_bill_customer_sk, 
           sh.ws_ship_date_sk, 
           sh.ws_item_sk, 
           sh.ws_net_profit * 0.9 AS ws_net_profit, 
           level + 1
    FROM SalesHierarchy AS sh
    JOIN web_sales AS ws ON ws.ws_bill_customer_sk = sh.ws_bill_customer_sk AND level < 5
    WHERE ws.ws_net_profit IS NOT NULL
), 
ProfitAggregates AS (
    SELECT sh.ws_bill_customer_sk,
           SUM(sh.ws_net_profit) AS total_net_profit,
           COUNT(sh.ws_item_sk) AS order_count
    FROM SalesHierarchy sh 
    GROUP BY sh.ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT c.c_customer_sk,
           d.cd_gender,
           d.cd_marital_status,
           CASE 
               WHEN d.cd_purchase_estimate IS NULL THEN 'Unknown'
               ELSE CASE 
                   WHEN d.cd_purchase_estimate < 500 THEN 'Low'
                   WHEN d.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
                   ELSE 'High'
               END 
           END AS purchase_estimate_category
    FROM customer c 
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.purchase_estimate_category, 
    COALESCE(pa.total_net_profit, 0) AS total_net_profit, 
    pa.order_count 
FROM CustomerDemographics cd 
LEFT JOIN ProfitAggregates pa ON cd.c_customer_sk = pa.ws_bill_customer_sk
WHERE 
    (cd.cd_gender = 'F' AND pa.total_net_profit > 1000)
    OR 
    (cd.cd_gender = 'M' AND pa.total_net_profit > 1500)
ORDER BY total_net_profit DESC 
LIMIT 100;
