
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales_data.total_sales
    FROM sales_data
    JOIN item ON sales_data.ws_item_sk = item.i_item_sk
    WHERE sales_data.sales_rank <= 10
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE 
        WHEN ci.total_spent IS NULL THEN 'No Purchases'
        WHEN ci.total_spent < 100 THEN 'Low Spender'
        WHEN ci.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category,
    ts.i_item_id,
    ts.i_product_name,
    ts.total_sales
FROM customer_info ci
JOIN top_sales ts ON ts.total_sales IS NOT NULL
ORDER BY ci.c_customer_id, ts.total_sales DESC
LIMIT 100
OPTION (RECOMPILE);
