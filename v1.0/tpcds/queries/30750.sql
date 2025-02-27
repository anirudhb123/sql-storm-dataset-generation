
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales 
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity, 
        sd.total_sales, 
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
returns_summary AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns
    WHERE wr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY wr_item_sk
)

SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    rs.total_returns,
    rs.total_return_amount
FROM top_sales ts
LEFT JOIN customer_info ci ON ci.c_customer_sk IN (
    SELECT DISTINCT ws_ship_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk = ts.ws_item_sk
)
LEFT JOIN returns_summary rs ON rs.wr_item_sk = ts.ws_item_sk
WHERE ts.sales_rank <= 10
ORDER BY ts.total_sales DESC;
