
WITH RECURSIVE inventory_levels AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_warehouse_sk, 
        inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
sales_summary AS (
    SELECT 
        hvc.c_customer_sk, 
        hvc.total_sales,
        hvc.order_count,
        COALESCE(AVG(icl.inv_quantity_on_hand), 0) AS avg_inventory
    FROM high_value_customers hvc
    LEFT JOIN inventory_levels icl ON 
        icl.inv_item_sk IN (
            SELECT i.i_item_sk
            FROM item i
            WHERE i.i_current_price > 100
        )
    GROUP BY hvc.c_customer_sk, hvc.total_sales, hvc.order_count
)
SELECT 
    hvc.sales_rank,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    ss.total_sales,
    ss.order_count,
    ss.avg_inventory
FROM sales_summary ss
JOIN customer c ON c.c_customer_sk = ss.c_customer_sk
JOIN store s ON 
    s.s_store_sk IN (
        SELECT DISTINCT ss_item_sk 
        FROM store_sales 
        WHERE ss_net_profit > 0
    )
ORDER BY ss.total_sales DESC, hvc.sales_rank
LIMIT 50;
