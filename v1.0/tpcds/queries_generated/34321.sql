
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_item_sk, 
           SUM(ss_quantity) AS total_quantity,
           MAX(ss_sold_date_sk) AS last_sale_date
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk
    HAVING SUM(ss_quantity) > 100
    UNION ALL
    SELECT s.ss_item_sk,
           s.total_quantity + sh.total_quantity,
           GREATEST(s.last_sale_date, sh.last_sale_date)
    FROM sales_hierarchy sh
    JOIN store_sales s ON sh.ss_item_sk = s.ss_item_sk
    WHERE s.ss_sold_date_sk > sh.last_sale_date
),
item_details AS (
    SELECT i.i_item_sk, 
           i.i_item_id, 
           i.i_product_name, 
           COALESCE(ih.total_quantity, 0) AS total_sales,
           ih.last_sale_date
    FROM item i
    LEFT JOIN sales_hierarchy ih ON i.i_item_sk = ih.ss_item_sk
),
customer_orders AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT s.ss_ticket_number) AS total_orders,
           MAX(s.ss_sold_date_sk) AS last_order_date,
           SUM(s.ss_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk
),
sales_summary AS (
    SELECT d.d_year,
           COUNT(DISTINCT co.c_customer_sk) AS active_customers,
           SUM(co.total_spent) AS total_revenue,
           SUM(i.total_sales) AS total_item_sales
    FROM date_dim d
    LEFT JOIN customer_orders co ON d.d_date_sk = co.last_order_date
    LEFT JOIN item_details i ON i.last_sale_date BETWEEN d.d_date_sk - 30 AND d.d_date_sk
    GROUP BY d.d_year
)
SELECT ss.d_year,
       ss.active_customers,
       ss.total_revenue,
       ss.total_item_sales,
       RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
FROM sales_summary ss
WHERE ss.active_customers > 10
ORDER BY ss.d_year;
