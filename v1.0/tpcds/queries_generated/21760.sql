
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
sales_summary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        AVG(cs_sales_price) AS avg_sale_per_order
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_order_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
aggregated_summary AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count,
        CASE 
            WHEN ss.total_sales > 0 THEN (COALESCE(rs.total_returns, 0) / ss.total_sales) * 100 
            ELSE NULL 
        END AS return_percentage,
        DENSE_RANK() OVER (PARTITION BY ch.level ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.cs_bill_customer_sk
    LEFT JOIN returns_summary rs ON ch.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    a.total_sales,
    a.order_count,
    a.total_returns,
    a.return_count,
    a.return_percentage,
    a.sales_rank
FROM aggregated_summary a
JOIN customer c ON a.c_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE a.return_percentage IS NOT NULL
    AND a.return_percentage > 0
ORDER BY a.sales_rank, a.total_sales DESC
LIMIT 100;
