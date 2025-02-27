WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE cd.cd_marital_status = 'M'
),
inventory_info AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity,
        MAX(inv_date_sk) AS last_inventory_date
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.ws_order_number,
    cs.ws_sales_price,
    ci.c_customer_id,
    ci.cd_gender,
    ci.hd_income_band_sk,
    inv.total_quantity,
    DENSE_RANK() OVER (PARTITION BY cs.ws_item_sk ORDER BY cs.ws_sales_price) AS price_rank
FROM web_sales cs
JOIN sales_data sd ON cs.ws_item_sk = sd.ws_item_sk AND cs.ws_order_number = sd.ws_order_number
JOIN customer_info ci ON ci.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = cs.ws_bill_customer_sk)
LEFT JOIN inventory_info inv ON inv.inv_item_sk = cs.ws_item_sk
WHERE inv.last_inventory_date >= sd.ws_sold_date_sk
AND ci.rank <= 5
AND (ci.hd_income_band_sk IS NOT NULL OR ci.hd_buy_potential LIKE '%High%')
ORDER BY price_rank, cs.ws_sales_price DESC
FETCH FIRST 50 ROWS ONLY;