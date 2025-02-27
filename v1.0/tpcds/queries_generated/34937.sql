
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    INNER JOIN customer_hierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
),
average_spend AS (
    SELECT 
        cd_demo_sk, 
        AVG(ss_net_paid) AS avg_spend
    FROM store_sales ss
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk
),
customer_returns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returned,
        COUNT(cr_returning_customer_sk) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS recent_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_returns, 0) AS total_returns
    FROM web_sales ws
    LEFT JOIN customer_returns cr ON ws.ws_ship_customer_sk = cr.cr_returning_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    cd.cd_marital_status,
    cd.cd_gender,
    avg.avg_spend,
    ss.ws_quantity,
    ss.ws_ext_sales_price,
    ss.recent_sales,
    CASE 
        WHEN ss.total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM customer_hierarchy ch
JOIN average_spend avg ON ch.c_customer_sk = avg.cd_demo_sk
JOIN sales_summary ss ON ch.c_current_addr_sk = ss.ws_item_sk
LEFT JOIN customer_demographics cd ON ch.c_customer_sk = cd.cd_demo_sk
WHERE avg.avg_spend > 100
AND ss.ws_ext_sales_price IS NOT NULL
ORDER BY avg.avg_spend DESC, ch.level, ch.c_last_name;
