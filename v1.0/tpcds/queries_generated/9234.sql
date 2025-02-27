
WITH customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           cd.cd_credit_rating, hd.hd_income_band_sk, hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), sales_summary AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_profit, COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), return_summary AS (
    SELECT sr_store_sk, SUM(sr_return_amt) AS total_refund, COUNT(sr_ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr_store_sk
), inventory_summary AS (
    SELECT inv_w.warehouse_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN warehouse inv_w ON inv.inv_warehouse_sk = inv_w.w_warehouse_sk
    GROUP BY inv_w.warehouse_sk
)
SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate,
       ci.cd_credit_rating, hs.hd_income_band_sk, hs.hd_buy_potential, ss.total_profit, ss.order_count,
       rs.total_refund, rs.return_count, is.total_quantity
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN return_summary rs ON ci.c_customer_sk = rs.sr_store_sk
LEFT JOIN inventory_summary is ON ci.c_customer_sk = is.warehouse_sk
WHERE ci.cd_purchase_estimate > 500
ORDER BY total_profit DESC, order_count DESC
LIMIT 100;
