
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
item_extended AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_sold_quantity,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_revenue,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
rich_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE cd.cd_credit_rating IS NOT NULL AND cd.cd_credit_rating = 'Excellent'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_income_band_sk
),
recent_sales AS (
    SELECT 
        ws.ws_item_sk,
        DENSE_RANK() OVER (ORDER BY ws.ws_sold_date_sk DESC) AS recent_rank,
        COUNT(ws.ws_order_number) AS sales_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.ws_item_sk
)
SELECT 
    ie.i_item_id,
    ie.i_product_name,
    ie.total_sold_quantity,
    ie.total_revenue,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_orders,
    JSON_AGG(DISTINCT res.recent_rank) AS recent_sales_ranks,
    CASE 
        WHEN ie.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM item_extended ie
JOIN rich_customers rc ON rc.total_orders > 0
LEFT JOIN recent_sales res ON res.ws_item_sk = ie.i_item_sk
GROUP BY ie.i_item_id, ie.i_product_name, ie.total_sold_quantity, ie.total_revenue, rc.c_first_name, rc.c_last_name, rc.total_orders
ORDER BY ie.total_revenue DESC
LIMIT 50;
