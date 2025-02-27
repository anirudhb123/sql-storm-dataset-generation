
WITH RECURSIVE sales_volume AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_revenue,
        CASE 
            WHEN SUM(ws_ext_sales_price) BETWEEN 0 AND 100 THEN 'Low'
            WHEN SUM(ws_ext_sales_price) BETWEEN 101 AND 500 THEN 'Medium'
            WHEN SUM(ws_ext_sales_price) > 500 THEN 'High'
        END AS revenue_band
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
), 
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ss_quantity) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        item i
        LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.total_orders,
    cs.total_revenue,
    cs.revenue_band,
    is.item_sales,
    is.total_store_sales,
    is.total_store_profit
FROM 
    customer_stats cs
LEFT OUTER JOIN (
    SELECT 
        is.i_item_sk,
        is.i_product_name,
        ROW_NUMBER() OVER (ORDER BY is.total_store_sales DESC) AS rank
    FROM 
        item_sales is
) AS is ON cs.total_orders = is.rank
WHERE 
    cs.total_revenue IS NOT NULL
    OR cs.total_orders > 0
ORDER BY 
    cs.total_revenue DESC, cs.c_customer_id;
