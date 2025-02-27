
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
CustomerCTE AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
), 
TopCustomers AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        c.cd_purchase_estimate
    FROM CustomerCTE c
    WHERE 
        c.gender_rank <= 5 AND 
        c.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
), 
ItemSales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_quantity,
        s.total_net_profit
    FROM SalesCTE s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    WHERE s.item_rank <= 10
)
SELECT 
    kc.c_first_name, 
    kc.c_last_name, 
    kc.cd_purchase_estimate,
    is.i_item_id, 
    is.i_item_desc, 
    is.total_quantity, 
    is.total_net_profit
FROM TopCustomers kc
JOIN ItemSales is ON kc.cd_purchase_estimate > 1500
ORDER BY kc.c_last_name, is.total_net_profit DESC;
