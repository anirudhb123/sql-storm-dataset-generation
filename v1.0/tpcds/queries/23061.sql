
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
Refunds AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_refunds
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_customer_sk
),
SalesWithRefunds AS (
    SELECT
        cs.c_customer_id,
        cs.total_store_sales,
        cs.num_transactions,
        COALESCE(r.total_refunds, 0) AS total_refunds,
        CASE 
            WHEN cs.total_store_sales IS NULL THEN 'No Sales'
            WHEN cs.total_store_sales > 0 AND COALESCE(r.total_refunds, 0) > cs.total_store_sales THEN 'High Refunds'
            ELSE 'Normal Sales'
        END AS sales_category
    FROM CustomerSales cs
    LEFT JOIN Refunds r ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = r.sr_customer_sk)
),
RankedSales AS (
    SELECT
        sw.c_customer_id,
        sw.total_store_sales,
        sw.num_transactions,
        sw.total_refunds,
        sw.sales_category,
        RANK() OVER (PARTITION BY sw.sales_category ORDER BY sw.total_store_sales DESC) AS sales_rank
    FROM SalesWithRefunds sw
)
SELECT 
    rs.c_customer_id,
    rs.total_store_sales,
    rs.num_transactions,
    rs.total_refunds,
    rs.sales_category,
    CASE 
        WHEN sales_rank <= 10 THEN 'Top 10 in Category'
        ELSE 'Below Top 10'
    END AS rank_category
FROM RankedSales rs
WHERE rs.num_transactions > 5 
    OR (rs.total_store_sales IS NULL AND rs.total_refunds > 0)
ORDER BY rs.sales_category, rs.total_store_sales DESC;
