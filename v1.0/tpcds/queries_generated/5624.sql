
WITH customer_data AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           hd.hd_income_band_sk,
           hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
combined_data AS (
    SELECT cd.c_customer_sk,
           cd.c_first_name,
           cd.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           hd.hd_income_band_sk,
           hd.hd_buy_potential,
           sd.total_profit,
           sd.total_orders,
           sd.total_quantity_sold
    FROM customer_data cd
    LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT c.c_first_name,
       c.c_last_name,
       c.cd_gender,
       c.cd_marital_status,
       c.cd_purchase_estimate,
       c.hd_income_band_sk,
       c.hd_buy_potential,
       COALESCE(c.total_profit, 0) AS total_profit,
       COALESCE(c.total_orders, 0) AS total_orders,
       COALESCE(c.total_quantity_sold, 0) AS total_quantity_sold
FROM combined_data c
WHERE c.cd_purchase_estimate > 5000
      AND c.hd_buy_potential IS NOT NULL
ORDER BY total_profit DESC
LIMIT 100;
