
WITH RECURSIVE sales_cte AS (
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid, 
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk) AS rn
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20200101 AND 20201231
), 
total_sales AS (
    SELECT 
        item.i_item_id,
        SUM(sales_cte.ss_quantity) as total_quantity,
        SUM(sales_cte.ss_net_paid) as total_net_paid
    FROM sales_cte
    JOIN item ON sales_cte.ss_item_sk = item.i_item_sk
    GROUP BY item.i_item_id
), 
customer_sales_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk IN (SELECT ss_sold_date_sk FROM store_sales)
    GROUP BY c.c_customer_id, cd.cd_gender
), 
top_customers AS (
    SELECT c.customer_id, ca.ca_city, 
           RANK() OVER (ORDER BY SUM(total_quantity_sold) DESC) as customer_rank
    FROM customer_sales_analysis c
    JOIN customer_address ca ON c.c_customer_id = ca.ca_address_id
    GROUP BY c.customer_id, ca.ca_city
)
SELECT 
    t.customer_id, 
    t.ca_city, 
    COALESCE(t.customer_rank, 0) AS rank,
    COALESCE(ts.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ts.total_net_paid, 0) AS total_net_paid
FROM top_customers t
LEFT JOIN total_sales ts ON t.customer_id = ts.i_item_id
ORDER BY rank, total_quantity_sold DESC;
