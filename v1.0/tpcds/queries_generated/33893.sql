
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sales_qty,
           SUM(ws_net_profit) AS total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT ws_item_sk, 
           total_sales_qty, 
           total_net_profit
    FROM SalesCTE
    WHERE rn <= 10
),
CustomerInfo AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_dep_count,
           cd.cd_purchase_estimate,
           COALESCE(cd.cd_credit_rating, 'Not Rated') AS credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT ti.ws_item_sk, 
           ti.total_sales_qty, 
           ti.total_net_profit, 
           ci.c_customer_sk, 
           ci.c_first_name, 
           ci.c_last_name
    FROM TopItems ti
    JOIN web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT sd.c_customer_sk, 
       sd.c_first_name, 
       sd.c_last_name, 
       sd.total_sales_qty,
       sd.total_net_profit,
       CASE 
           WHEN sd.total_net_profit > 500 THEN 'High Profit'
           WHEN sd.total_net_profit BETWEEN 100 AND 500 THEN 'Moderate Profit'
           ELSE 'Low Profit' 
       END AS profit_category
FROM SalesDetails sd
ORDER BY sd.total_sales_qty DESC, sd.total_net_profit DESC
LIMIT 100
UNION ALL
SELECT NULL AS c_customer_sk, 
       'Total' AS c_first_name, 
       NULL AS c_last_name, 
       SUM(total_sales_qty) AS total_sales_qty, 
       SUM(total_net_profit) AS total_net_profit,
       'Aggregated' AS profit_category
FROM SalesDetails;
