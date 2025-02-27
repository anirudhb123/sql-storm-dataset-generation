
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(ss.ticket_number) AS total_transactions,
        ROW_NUMBER() OVER(PARTITION BY ss.item_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS rank
    FROM store_sales ss
    WHERE ss.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ss.sold_date_sk, ss.item_sk
    HAVING SUM(ss.ext_sales_price) > 1000
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
)
SELECT 
    COALESCE(ca.ca_city, 'Unknown') AS customer_city,
    SUM(s.total_sales) AS total_sales_amount,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    MAX(s.total_transactions) AS max_transactions_per_item
FROM SalesCTE s
LEFT JOIN customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk IN (SELECT h.c_customer_sk FROM HighValueCustomers h))
LEFT JOIN HighValueCustomers h ON h.c_customer_sk IN (
    SELECT DISTINCT c.c_customer_sk 
    FROM customer c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_item_sk = s.item_sk
)
JOIN customer_demographics cd ON h.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY ca.ca_city
HAVING SUM(s.total_sales) > 10000
ORDER BY total_sales_amount DESC
LIMIT 10;
