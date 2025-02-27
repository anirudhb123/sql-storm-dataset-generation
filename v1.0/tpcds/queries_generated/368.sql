
WITH CustomerStats AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
           DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS overall_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT ws.ws_ship_date_sk,
           ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= (SELECT MAX(dd.d_date_sk) - 30 FROM date_dim dd)
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
HighValueItems AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           COALESCE(SUM(ws.total_net_profit), 0) AS total_profit
    FROM item i
    LEFT JOIN SalesInfo si ON i.i_item_sk = si.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
    HAVING total_profit > 1000
)
SELECT cs.c_first_name,
       cs.c_last_name,
       cs.cd_gender,
       hivi.i_product_name,
       hivi.total_profit,
       (SELECT COUNT(*) FROM customer_stats WHERE overall_rank <= 10) AS top_customers_count
FROM CustomerStats cs
JOIN HighValueItems hivi ON cs.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = hivi.i_item_sk LIMIT 1)
WHERE cs.gender_rank <= 5
  AND cs.cd_marital_status = 'M'
ORDER BY hivi.total_profit DESC, cs.c_last_name, cs.c_first_name
LIMIT 50;
