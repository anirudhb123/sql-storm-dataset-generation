
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk 
    WHERE c.c_current_cdemo_sk IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sales,
        MIN(ws_net_paid) AS min_sales,
        MAX(ws_net_paid) AS max_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
address_count AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM customer_address
    GROUP BY ca_state
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ss.total_sales,
    ss.avg_sales,
    ss.min_sales,
    ss.max_sales,
    ss.order_count,
    ac.address_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_rating
FROM customer_hierarchy ch
LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN address_count ac ON ac.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = ch.c_current_addr_sk)
WHERE (ss.total_sales > 500 OR ss.avg_sales > 100)
AND (ac.address_count IS NOT NULL OR ac.address_count > 5)
ORDER BY ch.c_first_name, ch.c_last_name;
