
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
    UNION ALL
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        SUM(s.ss_sales_price + sh.total_sales) AS total_sales,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_store_sk = sh.ss_store_sk
    WHERE 
        s.ss_item_sk = sh.ss_item_sk
    GROUP BY 
        s.ss_store_sk, s.ss_item_sk
),
item_inventory AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_sales_qty
    FROM 
        inventory inv
    LEFT JOIN 
        store_sales ss ON inv.inv_item_sk = ss.ss_item_sk
    GROUP BY 
        inv.inv_item_sk, inv.inv_quantity_on_hand
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
best_selling_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_sold
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
    HAVING 
        SUM(ss.ss_quantity) > 100
)
SELECT 
    sa.ss_store_sk,
    si.i_item_id,
    si.total_sold,
    ii.inv_quantity_on_hand,
    tc.total_spent,
    ri.r_reason_desc
FROM 
    store_sales sa
JOIN 
    best_selling_items si ON sa.ss_item_sk = si.i_item_sk
JOIN 
    item_inventory ii ON si.i_item_sk = ii.inv_item_sk
JOIN 
    top_customers tc ON sa.ss_customer_sk = tc.c_customer_sk
LEFT JOIN 
    reason ri ON sa.ss_item_sk = ri.r_reason_sk
WHERE 
    sa.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    AND si.total_sold > 0
ORDER BY 
    sa.ss_store_sk, si.total_sold DESC;
