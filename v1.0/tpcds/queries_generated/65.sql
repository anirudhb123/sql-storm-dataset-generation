
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
inventory_stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(i.i_current_price) AS avg_price
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    i.i_item_id,
    inv.total_quantity,
    inv.avg_price,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    top_customers tc
LEFT JOIN 
    inventory_stats inv ON inv.total_quantity > 0
JOIN 
    item i ON inv.inv_item_sk = i.i_item_sk
ORDER BY 
    tc.total_sales DESC, inv.total_quantity DESC;
