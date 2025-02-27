
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity_sold,
        sales.total_sales
    FROM sales_summary sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_birth_day,
        cd.cd_birth_month,
        cd.cd_birth_year,
        ca.ca_city
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
returns_info AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
final_report AS (
    SELECT 
        ts.i_item_id,
        ts.i_item_desc,
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ts.total_quantity_sold,
        ts.total_sales,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_returned_amount, 0) AS total_returned_amount,
        CASE 
            WHEN COALESCE(ri.total_returned_amount, 0) > 0 THEN 'Returned Items'
            ELSE 'No Returns'
        END AS return_status,
        CASE 
            WHEN ts.total_sales - COALESCE(ri.total_returned_amount, 0) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS sale_status
    FROM top_sales ts
    JOIN customer_info ci ON ci.c_customer_id IS NOT NULL
    LEFT JOIN returns_info ri ON ts.i_item_sk = ri.sr_item_sk
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    f.total_quantity_sold,
    f.total_sales,
    f.total_returns,
    f.total_returned_amount,
    f.return_status,
    f.sale_status
FROM final_report f
ORDER BY f.total_sales DESC, f.total_quantity_sold ASC;
