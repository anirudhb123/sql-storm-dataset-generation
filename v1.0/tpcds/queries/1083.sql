
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'UNKNOWN') AS credit_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY ws.ws_item_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer_summary cs
    JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cs.c_customer_sk
    HAVING COUNT(ws.ws_order_number) > 2
),
return_analysis AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.credit_status,
    pi.total_sales,
    tc.order_count,
    COALESCE(ra.total_returns, 0) AS total_item_returns,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount
FROM customer_summary cs
JOIN popular_items pi ON cs.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = pi.ws_item_sk)
JOIN top_customers tc ON cs.c_customer_sk = tc.c_customer_sk
LEFT JOIN return_analysis ra ON pi.ws_item_sk = ra.cr_item_sk
WHERE cs.rn <= 10
ORDER BY cs.c_last_name, cs.c_first_name;
