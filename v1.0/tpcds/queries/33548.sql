
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_month = 1 AND cd.cd_gender = 'F'
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50.00 AND ws.ws_ship_date_sk >= 20230101
    GROUP BY ws.ws_ship_date_sk, ws.ws_ship_mode_sk, ws.ws_item_sk
),
AggregateSales AS (
    SELECT 
        sd.ws_ship_date_sk, 
        sd.ws_ship_mode_sk,
        AVG(sd.total_net_paid) AS avg_net_paid,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
    FROM SalesData sd
    GROUP BY sd.ws_ship_date_sk, sd.ws_ship_mode_sk
)
SELECT 
    ch.c_customer_id,
    ch.cd_gender,
    ch.cd_purchase_estimate,
    asales.ws_ship_mode_sk,
    asales.avg_net_paid,
    asales.unique_items_sold,
    RANK() OVER (PARTITION BY asales.ws_ship_mode_sk ORDER BY asales.avg_net_paid DESC) AS rank
FROM CustomerHierarchy ch
LEFT JOIN AggregateSales asales ON ch.c_customer_sk = asales.ws_ship_mode_sk
WHERE ch.cd_purchase_estimate IS NOT NULL AND asales.avg_net_paid IS NOT NULL
ORDER BY ch.c_customer_id, asales.avg_net_paid DESC
FETCH FIRST 10 ROWS ONLY;
