
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd_gender
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        total_orders,
        total_spent
    FROM customer_summary
    WHERE total_spent > (SELECT AVG(total_spent) FROM customer_summary)
),
item_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    hi.total_orders,
    hi.total_spent,
    ii.inv_item_sk,
    ii.total_inventory,
    COALESCE(ii.total_inventory, 0) AS available_stock,
    CASE 
        WHEN ii.total_inventory IS NULL THEN 'Out of Stock'
        WHEN ii.total_inventory < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM high_value_customers hi
JOIN customer c ON hi.c_customer_sk = c.c_customer_sk
LEFT JOIN item_inventory ii ON hi.c_customer_sk = ii.inv_item_sk
WHERE hi.total_orders > 5
ORDER BY hi.total_spent DESC, ci.c_last_name ASC;
