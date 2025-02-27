
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesSummary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
ReturnsSummary AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_sales
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
DailySales AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_sales, 0) AS total_returned_sales
    FROM date_dim d
    LEFT JOIN SalesSummary ss ON d.d_date_sk = ss.ws_sold_date_sk
    LEFT JOIN ReturnsSummary rs ON d.d_date_sk = rs.sr_returned_date_sk
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS customer_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    dh.d_date,
    ds.total_quantity,
    ds.total_sales,
    ds.total_returns,
    ds.total_returned_sales,
    cs.customer_sales,
    (ds.total_sales - ds.total_returned_sales) AS net_sales,
    CASE 
        WHEN cs.customer_sales > 5000 THEN 'High Value'
        WHEN cs.customer_sales BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM DailySales ds
CROSS JOIN CustomerSales cs 
    ON cs.customer_sales = (SELECT MAX(customer_sales) FROM CustomerSales) 
LEFT JOIN CustomerHierarchy ch ON ch.c_customer_sk = cs.c_customer_sk
WHERE ds.total_sales > 100
ORDER BY ds.d_date DESC, net_sales DESC
LIMIT 50;
