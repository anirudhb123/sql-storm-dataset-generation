
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_item_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_item_sk
),
AddressDetails AS (
    SELECT ca_address_sk,
           CONCAT_WS(', ', ca_street_number, ca_street_name, ca_city, ca_state) AS full_address
    FROM customer_address
    WHERE ca_country = 'USA'
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_returning_customer_sk) AS unique_returning_customers
    FROM catalog_returns
    WHERE cr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%defective%')
    GROUP BY cr_item_sk
),
SalesWithReturns AS (
    SELECT sh.ws_item_sk,
           sh.total_sales,
           COALESCE(cr.total_returns, 0) AS total_returns,
           COALESCE(cr.unique_returning_customers, 0) AS unique_returning_customers
    FROM SalesHierarchy sh
    LEFT JOIN CustomerReturns cr ON sh.ws_item_sk = cr.cr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.total_returns,
    s.unique_returning_customers,
    CASE
        WHEN s.total_sales IS NULL THEN 0
        ELSE (s.total_returns / NULLIF(s.total_sales, 0)) * 100
    END AS return_percentage,
    (SELECT COUNT(*) 
     FROM AddressDetails ad 
     WHERE ad.ca_address_sk IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
     AND (SELECT COUNT(*) FROM CustomerReturns WHERE cr_item_sk = s.ws_item_sk) > 0) AS address_count
FROM SalesWithReturns s
WHERE s.total_sales > 1000
ORDER BY return_percentage DESC, total_sales DESC
FETCH FIRST 10 ROWS ONLY;
