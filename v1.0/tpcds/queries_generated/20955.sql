
WITH RECURSIVE inventory_summary AS (
    SELECT 
        inv.warehouse_sk,
        inv.item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NOT NULL THEN inv.inv_quantity_on_hand ELSE 0 END) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY inv.warehouse_sk ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS rank
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk, inv.item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS sales_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    ca.marital_status,
    COALESCE(i.total_quantity, 0) AS total_inventory_quantity,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = ca.c_customer_sk 
     AND ss.ss_quantity > 1) AS multiple_item_purchases,
    CASE 
        WHEN ca.total_spent > 1000 THEN 'High Value'
        WHEN ca.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer_analysis ca
LEFT JOIN 
    inventory_summary i ON ca.c_customer_sk = i.warehouse_sk -- joining on a non-standard relationship
ORDER BY 
    ca.total_spent DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    'Inventory Summary' AS c_first_name,
    NULL AS c_last_name,
    NULL AS marital_status,
    SUM(total_quantity) AS total_inventory_quantity,
    NULL AS multiple_item_purchases,
    NULL AS customer_value_category
FROM 
    inventory_summary
WHERE 
    rank <= 10
HAVING 
    SUM(total_quantity) > (SELECT AVG(total_quantity) FROM inventory_summary)
ORDER BY 
    total_inventory_quantity DESC;
