
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        ss.total_quantity, 
        ss.total_sales 
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.sales_rank <= 10
),
customer_stats AS (
    SELECT 
        cd_demo_sk,
        AVG(cd_purchase_estimate) AS avg_purchase,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_demo_sk
),
state_sales AS (
    SELECT 
        ca_state, 
        SUM(ws_ext_sales_price) AS state_sales_amount
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca_state
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    cs.avg_purchase,
    cs.customer_count,
    ss.state_sales_amount
FROM top_sales ts
JOIN customer_stats cs ON cs.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_id = (SELECT TOP 1 c_customer_id FROM customer ORDER BY NEWID()))
JOIN state_sales ss ON ss.state_sales_amount = (SELECT MAX(state_sales_amount) FROM state_sales);
