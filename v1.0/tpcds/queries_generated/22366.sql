
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_quantity) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY ss_store_sk, ss_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        ws.net_paid - (COALESCE(ws.ws_ext_discount_amt, 0) + COALESCE(ws.ws_ext_tax, 0)) AS net_after_discount_and_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2400 AND 2500
),
StoreReturnAmount AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) as total_return_amt,
        COUNT(sr_return_quantity) AS total_return_count
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2400 AND 2500
    GROUP BY sr_store_sk
)
SELECT 
    cs.c_last_name AS customer_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.store_sk,
    ss.total_quantity AS quantity_sold,
    COALESCE(sr.total_return_amt, 0) AS total_return_amt,
    COALESCE(sr.total_return_count, 0) AS total_return_count,
    s.wholesale_cost,
    ROUND(sd.net_after_discount_and_tax, 2) AS net_profit,
    RANK() OVER () AS overall_rank
FROM RankedSales ss
JOIN CustomerData cs ON cs.c_customer_sk = (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_item_sk = ss.ss_item_sk LIMIT 1)
LEFT JOIN StoreReturnAmount sr ON sr.sr_store_sk = ss.ss_store_sk
JOIN SalesDetails sd ON sd.ws_item_sk = ss.ss_item_sk 
FULL OUTER JOIN store s ON s.s_store_sk = ss.ss_store_sk
WHERE (sr.total_return_amt IS NOT NULL OR ss.total_quantity > 5)
AND (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > 2500)
ORDER BY overall_rank, total_quantity DESC;
