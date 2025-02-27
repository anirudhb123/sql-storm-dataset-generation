
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_current_price, i_size, 1 AS depth
    FROM item
    WHERE i_item_desc IS NOT NULL

    UNION ALL

    SELECT ih.i_item_sk, CONCAT(ih.i_item_desc, ' - ', i.i_item_desc) AS i_item_desc, i.i_brand, i.i_current_price, i.i_size, ih.depth + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk 
    WHERE ih.depth < 5
),
sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS average_order_value
    FROM web_sales
    WHERE ws_sold_date_sk IS NOT NULL
    GROUP BY ws_sold_date_sk
),
sales_ranked AS (
    SELECT 
        d.d_date AS sales_date,
        ss.total_sales,
        ss.total_orders,
        ss.average_order_value,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM sales_summary ss
    JOIN date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
),
customers_with_returns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS returns_count,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.returns_count, 0) AS returns_count,
    COALESCE(cr.total_return_value, 0.00) AS total_return_value,
    sr.sales_date,
    sr.total_sales,
    sr.total_orders,
    sr.average_order_value,
    CASE 
        WHEN cr.returns_count > 0 THEN 'Returned Customer' 
        ELSE 'New Customer' 
    END AS customer_status,
    item_h.i_brand,
    item_h.i_size,
    item_h.depth
FROM customer c
LEFT JOIN customers_with_returns cr ON c.c_customer_sk = cr.c_customer_sk
JOIN sales_ranked sr ON sr.sales_rank <= 10
JOIN item_hierarchy item_h ON item_h.i_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE c.c_birth_country IS NOT NULL
ORDER BY sr.total_sales DESC, c.c_first_name;
