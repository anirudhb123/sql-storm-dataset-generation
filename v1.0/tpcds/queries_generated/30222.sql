
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerCTE AS (
    SELECT c_customer_sk, 
           cd_gender,
           cd_marital_status,
           cd_income_band_sk,
           COALESCE(hd_buy_potential, 'None') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
ReturnStats AS (
    SELECT sr_item_sk,
           COUNT(DISTINCT sr_ticket_number) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalStats AS (
    SELECT s.ws_item_sk,
           s.total_quantity,
           s.total_profit,
           r.total_returns,
           r.total_return_amount,
           COUNT(DISTINCT c.cc_call_center_sk) AS call_centers_served
    FROM SalesCTE s
    LEFT JOIN ReturnStats r ON s.ws_item_sk = r.sr_item_sk
    LEFT JOIN call_center c ON s.ws_item_sk IN (
        SELECT DISTINCT cs_item_sk FROM catalog_sales WHERE cs_item_sk = s.ws_item_sk
    )
    GROUP BY s.ws_item_sk, s.total_quantity, s.total_profit, r.total_returns, r.total_return_amount
)
SELECT item.i_item_id, 
       item.i_item_desc,
       COALESCE(fs.total_quantity, 0) AS total_quantity,
       COALESCE(fs.total_profit, 0) AS total_profit,
       COALESCE(fs.total_returns, 0) AS total_returns,
       COALESCE(fs.total_return_amount, 0) AS total_return_amount,
       COUNT(DISTINCT cc.cc_call_center_sk) AS total_call_centers
FROM item
LEFT JOIN FinalStats fs ON item.i_item_sk = fs.ws_item_sk
LEFT JOIN CustomerCTE cc ON cc.cd_income_band_sk IN (
    SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= fs.total_profit AND ib_upper_bound >= fs.total_profit
)
WHERE fs.total_profit > 1000.00 OR fs.total_return_amount > 500.00
GROUP BY item.i_item_id, item.i_item_desc, fs.total_quantity, fs.total_profit, fs.total_returns, fs.total_return_amount
HAVING COUNT(DISTINCT cc.c_customer_sk) > 10
ORDER BY total_profit DESC;
