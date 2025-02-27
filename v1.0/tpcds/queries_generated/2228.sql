
WITH CustomerRanking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_net_profit,
        sd.avg_net_paid_inc_tax
    FROM item i
    JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE sd.total_quantity > (
        SELECT AVG(total_quantity) FROM SalesData
    )
    ORDER BY sd.total_net_profit DESC
    LIMIT 10
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    tr.cust_rank AS customer_rank,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit
FROM CustomerRanking tr
JOIN TopItems ti ON tr.c_customer_sk = (
    SELECT TOP 1 ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc = ti.i_item_desc)
    ORDER BY ws_sales_price DESC
)
LEFT JOIN customer_address ca ON ca.ca_address_sk = tr.c_customer_sk
WHERE tr.rank_by_estimate <= 5
AND ca.ca_city IS NOT NULL;
