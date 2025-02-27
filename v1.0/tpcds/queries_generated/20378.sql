
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2020 AND 2023
),
customer_revenue AS (
    SELECT c.c_customer_sk,
           COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_revenue,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT cr.c_customer_sk,
           cr.total_revenue,
           DENSE_RANK() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
    FROM customer_revenue cr
),
category_sales AS (
    SELECT i.i_item_sk,
           i.i_category,
           SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_quantity,
           SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_category
),
filtered_sales AS (
    SELECT cs.cs_order_number,
           SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
           COUNT(cs.cs_item_sk) AS item_count,
           MAX(cs.cs_sales_price) AS max_catalog_price
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_series)
    GROUP BY cs.cs_order_number
)
SELECT c.c_customer_id, 
       c.c_first_name, 
       c.c_last_name,
       COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
       CASE 
           WHEN cs.total_catalog_sales IS NULL THEN 'NO CATALOG SALES'
           ELSE 'HAS CATALOG SALES'
       END AS sales_status,
       COALESCE(top.total_revenue, 0) AS revenue,
       d.d_year,
       SUM(coalesce(q.total_quantity, 0) * coalesce(p.p_discount_active, 1)) AS adjusted_quantity
FROM customer c
LEFT JOIN top_customers top ON c.c_customer_sk = top.c_customer_sk
LEFT JOIN filtered_sales cs ON cs.cs_order_number IN (
    SELECT DISTINCT ws.ws_order_number 
    FROM web_sales ws 
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk
)
LEFT JOIN category_sales q ON q.i_item_sk IN (
    SELECT DISTINCT cr_i.i_item_sk
    FROM catalog_sales cr_cs
    JOIN item cr_i ON cr_cs.cs_item_sk = cr_i.i_item_sk
    WHERE cr_cs.cs_order_number = cs.cs_order_number
)
LEFT JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
RIGHT JOIN date_series d ON d.d_year = year(CURDATE())
WHERE (top.revenue_rank <= 10 OR top.revenue_rank IS NULL)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cs.total_catalog_sales, top.total_revenue, d.d_year;
