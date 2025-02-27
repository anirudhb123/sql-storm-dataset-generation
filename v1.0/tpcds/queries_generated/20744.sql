
WITH ranked_sales AS (
    SELECT 
        ss.store_sk,
        ss.sold_date_sk,
        ss.item_sk,
        ss.quantity,
        ss.ext_sales_price,
        RANK() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    GROUP BY ss.store_sk, ss.sold_date_sk, ss.item_sk, ss.quantity, ss.ext_sales_price
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
inventory_data AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.warehouse_sk
),
sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.web_site_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cs.total_net_profit,
    ir.total_quantity,
    rs.sales_rank
FROM customer_details cd
JOIN sales_summary cs ON cd.c_current_cdemo_sk = cs.web_site_sk
JOIN inventory_data ir ON ir.warehouse_sk = (SELECT MAX(w_warehouse_sk) FROM warehouse)
JOIN ranked_sales rs ON rs.store_sk = (SELECT MIN(s_store_sk) FROM store)
WHERE cd.gender_rank = 1
  AND COALESCE(cd.cd_marital_status, 'N') IN ('S', 'M')
  AND cs.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_summary WHERE total_orders > 10)
ORDER BY cd.cd_gender ASC, cs.total_net_profit DESC
LIMIT 100 OFFSET 50;
