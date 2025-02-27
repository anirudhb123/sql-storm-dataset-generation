
WITH RECURSIVE top_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_email_address, 
           SUM(ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name, c_email_address
    ORDER BY total_sales DESC
    LIMIT 10
),
total_sales_per_month AS (
    SELECT d.d_month_seq, SUM(ws_ext_sales_price) AS monthly_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),
avg_sales_by_gender AS (
    SELECT cd_gender, AVG(total_sales) AS avg_sales
    FROM (
        SELECT c.c_current_cdemo_sk, SUM(ws_ext_sales_price) AS total_sales
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        GROUP BY c.c_current_cdemo_sk
    ) sales_summary
    JOIN customer_demographics cd ON sales_summary.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
recent_store_returns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk = (
        SELECT MAX(sr_returned_date_sk) 
        FROM store_returns
    )
    GROUP BY sr_item_sk
)
SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.c_email_address,
    COALESCE(ts.monthly_sales, 0) AS sales_last_month,
    COALESCE(rs.total_returns, 0) AS returns_last_day,
    ag.avg_sales
FROM 
    top_customers tc
LEFT JOIN total_sales_per_month ts ON ts.d_month_seq = (
    SELECT MAX(d_month_seq)
    FROM date_dim
    WHERE d_year = YEAR(CURDATE())
)
LEFT JOIN recent_store_returns rs ON rs.sr_item_sk IN (
    SELECT i_item_sk 
    FROM item 
    WHERE i_item_id IN (
        SELECT distinct ws_item_sk
        FROM web_sales 
        WHERE ws_ship_date_sk IS NOT NULL
    )
)
CROSS JOIN avg_sales_by_gender ag
ORDER BY tc.total_sales DESC;
