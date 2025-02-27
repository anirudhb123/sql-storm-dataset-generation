
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
best_customers AS (
    SELECT 
        c.c_customer_id,
        COUNT(cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_id
    HAVING COUNT(cs.cs_order_number) > 5
),
avg_demo_income AS (
    SELECT 
        ib.ib_income_band_sk, 
        AVG(hd.hd_dep_count) AS avg_dep_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
item_inventory AS (
    SELECT 
        inv.inv_item_sk,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS available_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
sales_details AS (
    SELECT 
        ss.ss_item_sk, 
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(ss.total_quantity, 0) AS online_quantity_sold,
    COALESCE(bc.order_count, 0) AS best_customers_order_count,
    COALESCE(bc.total_spent, 0) AS best_customers_spent,
    COALESCE(ai.avg_dep_count, 0) AS avg_dependents,
    COALESCE(ii.available_stock, 0) AS stock_in_inventory,
    COALESCE(sd.total_store_profit, 0) AS total_store_profit,
    COALESCE(sd.total_store_quantity, 0) AS total_store_quantity
FROM item i
LEFT JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN best_customers bc ON ss.ws_item_sk = bc.order_count
LEFT JOIN avg_demo_income ai ON ai.ib_income_band_sk = (SELECT hd.hd_income_band_sk FROM household_demographics hd WHERE hd.hd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk IN (SELECT DISTINCT cs.cs_bill_customer_sk FROM catalog_sales cs WHERE cs.cs_item_sk = i.i_item_sk)) LIMIT 1)
LEFT JOIN item_inventory ii ON i.i_item_sk = ii.inv_item_sk
LEFT JOIN sales_details sd ON i.i_item_sk = sd.ss_item_sk
WHERE 
    (i.i_item_desc LIKE '%special%' OR ii.available_stock > 10)
    AND (bc.order_count IS NOT NULL OR ss.total_quantity > 100)
ORDER BY 
    COALESCE(ss.total_profit, 0) DESC,
    i.i_item_id
FETCH FIRST 100 ROWS ONLY;
