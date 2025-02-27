
WITH RECURSIVE sales_rank AS (
    SELECT ws_item_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
customer_summary AS (
    SELECT c.c_customer_sk,
           cd.cd_gender,
           SUM(ws_ext_sales_price) AS total_spent,
           COUNT(ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
high_value_customers AS (
    SELECT c.c_customer_sk,
           cs.total_spent,
           cs.total_orders,
           DENSE_RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM customer_summary cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent > 500
),
top_items AS (
    SELECT sr.ws_item_sk,
           sr.total_sales,
           s.s_store_sk
    FROM sales_rank sr
    JOIN store s ON sr.ws_item_sk IN (SELECT cs_item_sk FROM store_sales WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales))
    )
    WHERE sr.rank <= 10
)
SELECT ci.item_id,
       ci.total_sales,
       cc.total_spent,
       cc.cd_gender,
       t.s_store_sk,
       t.ws_item_sk
FROM top_items t
JOIN catalog_sales cs ON t.ws_item_sk = cs.cs_item_sk
LEFT JOIN (
    SELECT hvc.c_customer_sk,
           hvc.total_spent,
           hvc.customer_rank,
           cd.cd_gender
    FROM high_value_customers hvc
    JOIN customer_demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
) cc ON cc.total_spent > 500
WHERE cc.customer_rank IS NOT NULL OR cc.cd_gender IS NOT NULL
ORDER BY ci.total_sales DESC, cc.total_spent DESC;
