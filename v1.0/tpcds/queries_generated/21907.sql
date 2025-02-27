
WITH AddressStats AS (
    SELECT ca_city, 
           COUNT(DISTINCT c_customer_sk) AS customer_count, 
           AVG(DATEDIFF(CURRENT_DATE, CONCAT(c_birth_year, '-', c_birth_month, '-', c_birth_day))) AS avg_age
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_city
),
SalesData AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity_sold, 
           SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
NullReturns AS (
    SELECT cr_item_sk, 
           COUNT(*) AS return_count,
           COALESCE(SUM(cr_return_amount), 0) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT a.ca_city, 
       a.customer_count, 
       a.avg_age,
       s.total_quantity_sold, 
       s.total_sales,
       n.return_count,
       n.total_return_amount
FROM AddressStats a
LEFT JOIN SalesData s ON s.ws_item_sk IN (SELECT DISTINCT ws_item_sk 
                                            FROM web_sales 
                                            WHERE ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) 
                                                                      FROM web_sales
                                                                      WHERE ws_quantity > 0))
LEFT JOIN NullReturns n ON n.cr_item_sk = s.ws_item_sk
WHERE a.customer_count > 10
  AND (n.return_count > 0 OR s.total_sales IS NULL OR n.total_return_amount IS NULL)
ORDER BY a.ca_city, s.total_sales DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
