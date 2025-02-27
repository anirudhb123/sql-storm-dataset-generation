
WITH RECURSIVE sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    GROUP BY cs_item_sk
),
top_sales AS (
    SELECT 
        ss.sold_date_sk,
        ss_item_sk, 
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM store_sales ss
    JOIN sales_summary ss_sum ON ss.ss_item_sk = ss_sum.cs_item_sk
    WHERE ss_sum.sales_rank <= 10
    GROUP BY ss.sold_date_sk, ss_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_credit_rating
),
aggregated_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ts.sold_date_sk,
    ts.ss_item_sk,
    ts.total_store_sales,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    ar.total_returns,
    ar.total_return_value
FROM top_sales ts
LEFT JOIN customer_stats cs ON ts.ss_item_sk = cs.c_customer_sk
LEFT JOIN aggregated_returns ar ON ts.ss_item_sk = ar.sr_item_sk
WHERE 
    (cs.total_orders > 5 OR cs.total_spent > 1000) AND 
    (ar.total_returns IS NULL OR ar.total_return_value < 500)
ORDER BY ts.total_store_sales DESC, cs.total_spent DESC
LIMIT 50;
