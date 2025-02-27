
WITH RECURSIVE category_hierarchy AS (
    SELECT i_category_id, i_category, 1 AS level
    FROM item
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.i_category_id, i.i_category, ch.level + 1
    FROM item i
    JOIN category_hierarchy ch ON i.i_category_id = ch.i_category_id
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459801 AND 2459808
    GROUP BY ws_bill_customer_sk
),
returns_data AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN returns_data rd ON c.c_customer_sk = rd.sr_customer_sk
)
SELECT 
    cs.c_state,
    cs.cd_gender,
    SUM(cs.total_sales) AS total_sales_by_gender,
    AVG(cs.net_sales) AS avg_net_sales_by_state,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count
FROM customer_summary cs
WHERE cs.net_sales > 0 
AND cs.cd_marital_status = 'M'
GROUP BY cs.c_state, cs.cd_gender
HAVING SUM(cs.total_sales) > 1000
ORDER BY total_sales_by_gender DESC
LIMIT 10;
