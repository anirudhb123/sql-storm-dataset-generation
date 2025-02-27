
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) as total_quantity,
        SUM(ws_net_paid) as total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) as rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(ss.total_quantity, 0) as total_quantity,
        COALESCE(ss.total_revenue, 0) as total_revenue,
        CASE 
            WHEN COALESCE(ss.total_quantity, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(ss.total_revenue, 0) < 100 THEN 'Low Sales'
            ELSE 'High Sales'
        END as sales_performance
    FROM item i
    LEFT JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
), 
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_net_paid) AS total_spent,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ids.i_item_id,
    ids.i_item_desc,
    ids.total_quantity,
    ids.total_revenue,
    ids.sales_performance,
    cs.orders_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent >= 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_status
FROM item_details ids
LEFT JOIN customer_sales cs ON ids.total_quantity > 0
ORDER BY ids.total_revenue DESC, cs.total_spent DESC;
