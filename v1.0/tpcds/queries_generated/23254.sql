
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS hierarchy_level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.hierarchy_level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE c.c_customer_sk <> ch.c_customer_sk
),
sales_summary AS (
    SELECT ws_ship_date_sk, SUM(ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws_order_number) AS order_count,
           COUNT(DISTINCT ws_bill_customer_sk) AS customer_count,
           ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_ship_date_sk
),
inventory_summary AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_item_sk
),
large_returns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) as total_returned_qty
    FROM store_returns
    GROUP BY sr_item_sk HAVING SUM(sr_return_quantity) > 10
),
combined_summary AS (
    SELECT D.d_date AS sales_date, COALESCE(ss.total_net_profit, 0) AS total_profit,
           COALESCE(ss.order_count, 0) AS total_orders,
           COALESCE(ss.customer_count, 0) AS unique_customers,
           COALESCE(i.total_quantity, 0) AS quantity_on_hand,
           COALESCE(lr.total_returned_qty, 0) AS large_returns_qty
    FROM date_dim D
    LEFT JOIN sales_summary ss ON D.d_date_sk = ss.ws_ship_date_sk
    LEFT JOIN inventory_summary i ON i.inv_item_sk IN (
        SELECT sr_item_sk FROM large_returns
    )
    LEFT JOIN large_returns lr ON lr.sr_item_sk = i.inv_item_sk
    WHERE D.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
final_results AS (
    SELECT *, 
           CASE 
               WHEN total_profit > 1000 THEN 'High Profit'
               WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
               ELSE 'Low Profit'
           END AS profit_category,
           CASE 
               WHEN unique_customers = 0 THEN 'No Customers'
               ELSE 'Active Customers'
           END AS customer_status,
           ROW_NUMBER() OVER (ORDER BY sales_date) AS sales_index
    FROM combined_summary
)
SELECT sales_date, total_profit, total_orders, unique_customers, quantity_on_hand, 
       large_returns_qty, profit_category, customer_status, sales_index
FROM final_results
WHERE (total_profit IS NOT NULL AND total_orders > 0)
  OR (quantity_on_hand > 0 AND large_returns_qty > 0)
ORDER BY sales_date DESC;
