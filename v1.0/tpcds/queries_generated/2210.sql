
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), high_value_customers AS (
    SELECT 
        c.customer_id,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)  
), item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), top_items AS (
    SELECT 
        i.i_item_id,
        is.total_quantity_sold,
        ROW_NUMBER() OVER (ORDER BY is.total_quantity_sold DESC) AS item_rank
    FROM item i
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
    WHERE is.total_quantity_sold > 50
)

SELECT 
    c.first_name,
    c.last_name,
    hvc.total_spent,
    hvc.order_count,
    ti.i_item_id,
    ti.total_quantity_sold
FROM high_value_customers hvc
JOIN top_items ti ON hvc.order_count > 3
JOIN customer c ON hvc.customer_id = c.c_customer_id
LEFT JOIN item_categories ic ON ti.i_item_id = ic.category_id
WHERE c.c_current_addr_sk IS NOT NULL
ORDER BY hvc.total_spent DESC, ti.total_quantity_sold DESC
FETCH FIRST 100 ROWS ONLY;
