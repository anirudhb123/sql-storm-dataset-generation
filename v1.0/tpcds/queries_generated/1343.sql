
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rnk
    FROM web_sales
),
total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM ranked_sales
    WHERE rnk <= 5
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category
    FROM item i
    WHERE i.i_rec_end_date IS NULL
),
revenue_data AS (
    SELECT 
        ti.i_item_sk,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_revenue,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM total_sales ts
    JOIN item_info ti ON ts.ws_item_sk = ti.i_item_sk
    LEFT JOIN catalog_sales cs ON ts.ws_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
    GROUP BY ti.i_item_sk
)
SELECT 
    cinfo.c_customer_sk,
    cinfo.c_first_name,
    cinfo.c_last_name,
    SUM(rd.total_revenue) AS total_revenue,
    COUNT(rd.order_count) AS total_orders,
    MAX(CASE WHEN cd.cd_gender = 'M' THEN rd.total_revenue END) AS male_revenue,
    MAX(CASE WHEN cd.cd_gender = 'F' THEN rd.total_revenue END) AS female_revenue
FROM revenue_data rd
JOIN customer_info cinfo ON cinfo.c_customer_sk = rd.i_item_sk
LEFT JOIN customer_demographics cd ON cinfo.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY cinfo.c_customer_sk, cinfo.c_first_name, cinfo.c_last_name
HAVING SUM(rd.total_revenue) > 1000
ORDER BY total_revenue DESC
LIMIT 10;
