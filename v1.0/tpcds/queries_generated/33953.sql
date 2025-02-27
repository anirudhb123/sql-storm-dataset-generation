
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        1 AS level
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk

    UNION ALL

    SELECT 
        ss.bill_customer_sk AS customer_sk,
        SUM(ss.net_paid) AS total_sales,
        sh.level + 1
    FROM store_sales ss
    JOIN sales_hierarchy sh ON sh.customer_sk = ss.ss_customer_sk
    GROUP BY ss.bill_customer_sk
),
category_totals AS (
    SELECT 
        i_category,
        SUM(ws_ext_sales_price) AS total_web_sales,
        RANK() OVER (PARTITION BY i_category ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i_category
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COALESCE(MAX(sh.total_sales), 0) AS total_catalog_sales,
    ct.total_web_sales AS total_category_sales,
    ct.sales_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk
LEFT JOIN category_totals ct ON ct.total_web_sales > 10000  -- Only categories with significant sales
WHERE ca.ca_state IS NOT NULL
  AND (ct.sales_rank BETWEEN 1 AND 5 OR ct.total_web_sales > 5000) -- Conditions on category
GROUP BY c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ct.total_web_sales, ct.sales_rank
ORDER BY total_web_sales DESC, total_catalog_sales DESC;
