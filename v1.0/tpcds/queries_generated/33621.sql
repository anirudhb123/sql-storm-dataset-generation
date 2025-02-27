
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_year, d_month_seq, d_week_seq, d_dow, d_year AS hierarchy_year
    FROM date_dim
    WHERE d_date >= '2020-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_year, d.d_month_seq, d.d_week_seq, d.d_dow, d.hierarchy_year
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk + 1
), 
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
), 
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS average_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM DateHierarchy)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.average_sales, 0) AS average_sales,
    sa.order_count,
    CASE 
        WHEN sa.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN SalesAnalysis sa ON c.c_customer_sk = sa.customer_sk
WHERE ca.ca_state IS NOT NULL 
AND (cr.total_returns > 0 OR sa.total_sales > 0)
ORDER BY total_sales DESC, total_returns DESC;
