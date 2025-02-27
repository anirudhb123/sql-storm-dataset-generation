
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        0 AS level
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity > 0
    
    UNION ALL

    SELECT 
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt_inc_tax,
        sh.level + 1
    FROM 
        store_returns sr
    JOIN 
        sales_hierarchy sh ON sr_item_sk = sh.sr_item_sk 
    WHERE 
        sh.level < 5
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        MAX(i.i_current_price) AS max_price,
        MIN(i.i_wholesale_cost) AS min_cost
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cust.full_name,
    cust.cd_gender,
    cust.purchase_estimate,
    COALESCE(sh.sr_return_quantity, 0) AS total_returned_quantity,
    COALESCE(sh.sr_return_amt_inc_tax, 0) AS total_returned_amount,
    inv.total_quantity_on_hand,
    inv.max_price,
    inv.min_cost
FROM 
    customer_data cust
LEFT JOIN 
    sales_hierarchy sh ON cust.c_customer_sk = sh.sr_item_sk
JOIN 
    inventory_summary inv ON sh.sr_item_sk = inv.inv_item_sk
WHERE 
    (cust.rank <= 10 OR cust.purchase_estimate IS NULL)
    AND (inv.total_quantity_on_hand > 0 OR inv.max_price IS NOT NULL)
ORDER BY 
    cust.purchase_estimate DESC, 
    inv.max_price ASC
LIMIT 100;
