
WITH sales_data AS (
    SELECT
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451386 AND 2451440 -- date range for testing purposes
    GROUP BY ws_ship_mode_sk
),
customer_analysis AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating, 
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS gender_sales_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
product_rating AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        CASE 
            WHEN wt.total_sales > 1000 THEN 'High'
            WHEN wt.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_rating
    FROM item i
    LEFT JOIN (
        SELECT 
            ws.ws_item_sk,
            SUM(ws.ws_ext_sales_price) AS total_sales
        FROM web_sales ws
        GROUP BY ws.ws_item_sk
    ) wt ON i.i_item_sk = wt.ws_item_sk
)
SELECT 
    a.c_first_name,
    a.c_last_name,
    b.sm_ship_mode_id,
    SUM(b.total_quantity) AS total_quantity,
    COUNT(DISTINCT c.i_item_sk) AS unique_products,
    MAX(r.sales_rating) AS highest_product_rating,
    COALESCE(MAX(d.total_sales), 0) AS top_sales_customer,
    COUNT(DISTINCT CASE WHEN a.gender_sales_rank = 1 THEN a.c_customer_sk END) AS top_gender_customers
FROM sales_data b
JOIN customer_analysis a ON a.total_sales > 0 -- ensuring we only get customers with sales
LEFT JOIN product_rating r ON b.ws_ship_mode_sk = r.i_item_sk
LEFT JOIN customer d ON a.c_customer_sk = d.c_customer_sk
GROUP BY a.c_first_name, a.c_last_name, b.sm_ship_mode_id
HAVING SUM(b.total_quantity) > 50 AND MAX(r.sales_rating) IS NOT NULL
ORDER BY total_quantity DESC, a.c_last_name ASC
LIMIT 100 OFFSET 10;
