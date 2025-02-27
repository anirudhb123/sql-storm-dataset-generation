
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT ih.i_item_sk, ih.i_item_id, ih.i_item_desc, ih.i_current_price * 0.9 AS i_current_price, ih.level + 1
    FROM item_hierarchy ih
    JOIN item ON ih.i_item_sk = item.i_item_sk
    WHERE ih.level < 5 AND item.i_current_price IS NOT NULL
), 
customer_details AS (
    SELECT c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
), 
total_inventory AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
), 
sales_info AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_net_profit) AS total_profit, 
           SUM(ws.ws_quantity) AS total_sold
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), 
final_summary AS (
    SELECT 
        cd.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COALESCE(SUM(si.total_profit), 0) AS total_profit,
        COALESCE(SUM(si.total_sold), 0) AS total_sales,
        COALESCE(SUM(ti.total_quantity), 0) AS total_inventory,
        ihi.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(si.total_profit), 0) DESC) AS profit_rank
    FROM customer_details cd
    LEFT JOIN sales_info si ON cd.c_customer_sk = si.ws_item_sk
    LEFT JOIN total_inventory ti ON si.ws_item_sk = ti.inv_item_sk
    LEFT JOIN item_hierarchy ihi ON ihi.i_item_sk = si.ws_item_sk
    GROUP BY cd.c_customer_sk, cd.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, ihi.i_item_desc
)
SELECT *
FROM final_summary
WHERE profit_rank <= 3
AND (cd_marital_status = 'M' OR cd_marital_status IS NULL)
ORDER BY total_profit DESC, total_sales DESC;
