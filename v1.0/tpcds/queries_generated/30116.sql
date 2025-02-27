
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, s_number_employees, s_floor_space, s_market_id, 
           s_division_id, s_company_id, s_market_desc, s_manager, 0 as level 
    FROM store 
    WHERE s_division_id IS NOT NULL
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, s.s_number_employees, s.s_floor_space, s.market_id, 
           s.division_id, s.company_id, s.market_desc, s.manager, sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s_division_id = sh.s_division_id
), 
customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING total_sales > (SELECT AVG(total_sales) 
                          FROM (SELECT SUM(ws_sales_price) AS total_sales
                                FROM web_sales 
                                GROUP BY ws_bill_customer_sk) subquery)
),
inventory_check AS (
    SELECT inv.inv_warehouse_sk, SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
    HAVING SUM(inv.inv_quantity_on_hand) < 100
)
SELECT 
    sh.s_store_name,
    (CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
     END) AS gender,
    ROUND(COALESCE(cs.total_sales, 0), 2) AS customer_sales,
    ROUND(ic.total_inventory / 100.0, 2) AS inventory_ratio
FROM sales_hierarchy sh
LEFT JOIN customer_demographics cd ON sh.s_store_sk = cd.cd_demo_sk
LEFT JOIN customer_sales cs ON cd.cd_demo_sk = cs.c_customer_sk
LEFT JOIN inventory_check ic ON ic.inv_warehouse_sk = sh.s_store_sk
WHERE sh.level = 0
ORDER BY customer_sales DESC, inventory_ratio ASC;
