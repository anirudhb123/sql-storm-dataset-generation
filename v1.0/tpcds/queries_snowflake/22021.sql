
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        CASE 
            WHEN SUM(wr_return_amt) < 0 THEN 'Negative Returns'
            ELSE 'Positive Returns'
        END AS return_status
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
customer_performance AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN returns_summary rs ON ch.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cp.total_sales,
    cp.order_count,
    cp.total_returns,
    cp.total_return_amt,
    CASE 
        WHEN cp.total_sales > 10000 THEN 'High Value Customer'
        WHEN cp.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    (SELECT COUNT(*) FROM store_sales WHERE ss_customer_sk = c.c_customer_sk) AS store_sales_count,
    (SELECT COUNT(*) FROM catalog_sales WHERE cs_bill_customer_sk = c.c_customer_sk) AS catalog_sales_count,
    (SELECT MAX(ss_net_paid) FROM store_sales WHERE ss_customer_sk = c.c_customer_sk) AS max_single_transaction,
    (SELECT AVG(ss_net_paid) FROM store_sales WHERE ss_customer_sk = c.c_customer_sk) AS avg_transaction_value,
    CASE 
        WHEN (SELECT COUNT(*) FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk) > 10 THEN 'Frequent Shopper'
        ELSE 'Occasional Shopper'
    END AS shopper_type
FROM customer c
JOIN customer_performance cp ON c.c_customer_sk = cp.c_customer_sk
WHERE (cp.order_count > 0 OR cp.total_returns > 0)
ORDER BY cp.total_sales DESC, cp.order_count DESC
LIMIT 50;
