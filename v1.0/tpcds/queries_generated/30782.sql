
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesStats AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS average_transaction_value
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_store_sk
),
RefundStats AS (
    SELECT 
        sr.sr_store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_refunds,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    GROUP BY sr.sr_store_sk
),
CombinedStats AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_sales,
        ss.total_transactions,
        ss.average_transaction_value,
        COALESCE(rs.total_refunds, 0) AS total_refunds,
        COALESCE(rs.avg_return_quantity, 0) AS avg_return_quantity
    FROM SalesStats ss
    LEFT JOIN RefundStats rs ON ss.ss_store_sk = rs.sr_store_sk
)
SELECT 
    s.s_store_id,
    cs.total_sales,
    cs.total_transactions,
    cs.average_transaction_value,
    cs.total_refunds,
    cs.avg_return_quantity,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
    CASE 
        WHEN cs.total_sales > 100000 THEN 'High Performer' 
        WHEN cs.total_sales BETWEEN 50000 AND 100000 THEN 'Average Performer' 
        ELSE 'Low Performer' 
    END AS performance_category
FROM CombinedStats cs
JOIN store s ON cs.ss_store_sk = s.s_store_sk
WHERE cs.total_sales IS NOT NULL
AND EXISTS (
    SELECT 1 FROM customer_demographics cd 
    WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
)
ORDER BY sales_rank;
