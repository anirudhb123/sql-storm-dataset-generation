
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cds.cd_marital_status, 
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cds ON c.c_current_cdemo_sk = cds.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cds.cd_marital_status, cd.cd_gender
    
    UNION ALL
    
    SELECT 
        ch.customer_sk, 
        ch.first_name, 
        ch.last_name,
        ch.marital_status,
        ch.gender,
        SUM(ws.ws_net_profit) + SUM(sh.sub_profit) AS total_profit
    FROM (
        SELECT 
            ch.c_customer_sk AS customer_sk, 
            ch.c_first_name AS first_name, 
            ch.c_last_name AS last_name,
            cds.cd_marital_status as marital_status,
            cd.cd_gender as gender,
            ws.ws_net_profit as sub_profit
        FROM customer ch
        JOIN customer_demographics cds ON ch.c_current_cdemo_sk = cds.cd_demo_sk
        JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2023
    ) AS ch
    JOIN sales_hierarchy sh ON ch.customer_sk = sh.c_customer_sk
    GROUP BY ch.customer_sk, ch.first_name, ch.last_name, ch.marital_status, ch.gender
)

SELECT 
    sh.c_first_name, 
    sh.c_last_name, 
    sh.cd_marital_status,
    sh.cd_gender, 
    sh.total_profit,
    CASE 
        WHEN sh.total_profit > 1000 THEN 'High Value Customer'
        WHEN sh.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM sales_hierarchy sh
ORDER BY total_profit DESC
LIMIT 10;

WITH inventory_details AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)

SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    i.i_current_price,
    COALESCE(inv.total_quantity, 0) AS current_inventory,
    CASE 
        WHEN inv.total_quantity IS NULL THEN 'Out of Stock'
        WHEN inv.total_quantity < 50 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS inventory_status
FROM item i
LEFT JOIN inventory_details inv ON i.i_item_sk = inv.inv_item_sk
WHERE i.i_current_price > (
    SELECT AVG(i_current_price) 
    FROM item 
    WHERE i_current_price > 0
)
ORDER BY i.i_current_price DESC;
