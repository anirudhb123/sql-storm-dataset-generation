
WITH CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating,
           hd.hd_income_band_sk, hd.hd_buy_potential, hd.hd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           ws.ws_ship_date_sk
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_ship_date_sk
),
InventoryData AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
DailySales AS (
    SELECT d.d_date_sk, SUM(sd.total_profit) AS daily_profit, SUM(sd.total_quantity) AS daily_quantity
    FROM date_dim d
    JOIN SalesData sd ON d.d_date_sk = sd.ws_ship_date_sk
    GROUP BY d.d_date_sk
)
SELECT cd.c_customer_id, cd.c_first_name, cd.c_last_name, cd.cd_gender, 
       cd.cd_marital_status, cs.ps_promo_name, ds.daily_profit, ds.daily_quantity, 
       id.total_stock
FROM CustomerDetails cd
LEFT JOIN catalog_sales cs ON cd.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN DailySales ds ON ds.d_daily_date = cs.cs_sold_date_sk
LEFT JOIN InventoryData id ON id.inv_item_sk = cs.cs_item_sk
WHERE cd.cd_purchase_estimate > 1000
AND ds.daily_profit > 500
ORDER BY ds.daily_profit DESC, cd.c_last_name ASC
LIMIT 100;
