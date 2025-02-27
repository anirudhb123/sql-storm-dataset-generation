
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS average_sales,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss.ss_store_sk
),
CustomerReturns AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_amt_inc_tax) AS average_return_amount
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY wr.wr_returning_customer_sk
)
SELECT 
    ca.ca_address_id,
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
    COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS web_order_count,
    COALESCE(SUM(ss.total_sales), 0) AS total_store_sales,
    COALESCE(MAX(cr.total_returned), 0) AS max_returned,
    ROW_NUMBER() OVER (PARTITION BY cu.c_customer_sk ORDER BY MAX(cr.return_count) DESC) AS customer_rank
FROM customer cu
LEFT JOIN customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN StoreSalesSummary ss ON cu.c_customer_sk = ss.ss_store_sk
LEFT JOIN CustomerReturns cr ON cu.c_customer_sk = cr.wr_returning_customer_sk
WHERE (cu.c_birth_month IS NULL OR cu.c_birth_month IN (SELECT d_moy FROM date_dim WHERE d_holiday = 'Y'))
    AND ca.ca_country = 'USA'
GROUP BY ca.ca_address_id, cu.c_first_name, cu.c_last_name
HAVING SUM(ws.ws_sales_price) > (SELECT AVG(ws_ext_sales_price) FROM web_sales ws) 
    OR (COUNT(DISTINCT ws.ws_order_number) = 0 AND MAX(cr.total_returned) > 0)
ORDER BY customer_rank, total_web_sales DESC;
