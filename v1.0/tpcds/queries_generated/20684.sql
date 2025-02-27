
WITH RecursiveSales AS (
    SELECT ws.web_site_sk, ws.ws_order_number, ws.ws_sales_price, 
           DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
),
FilteredSales AS (
    SELECT fs.web_site_sk, SUM(fs.ws_sales_price) AS total_sales
    FROM RecursiveSales fs
    WHERE fs.rank_price <= 10
    GROUP BY fs.web_site_sk
),
MaxSales AS (
    SELECT MAX(total_sales) AS max_total
    FROM FilteredSales
),
MinSales AS (
    SELECT MIN(total_sales) AS min_total
    FROM FilteredSales
),
WebsiteInfo AS (
    SELECT w.web_site_id, w.web_name, fs.total_sales
    FROM web_site w
    JOIN FilteredSales fs ON w.web_site_sk = fs.web_site_sk
)
SELECT wi.web_site_id, wi.web_name, 
       CASE 
           WHEN wi.total_sales = (SELECT max_total FROM MaxSales) THEN 'Top Seller'
           WHEN wi.total_sales = (SELECT min_total FROM MinSales) THEN 'Bottom Seller'
           ELSE 'Regular Seller'
       END AS seller_category,
       COALESCE(wi.total_sales, 0) AS sales_value,
       (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20210331 
        AND ws.ws_shipping_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'AIR')) AS air_ship_count
FROM WebsiteInfo wi
LEFT JOIN (SELECT DISTINCT c.c_customer_id
            FROM customer c
            WHERE c.c_birth_year IS NOT NULL AND c.c_first_name IS NOT NULL) AS ValidCustomers
ON wi.web_site_id = ValidCustomers.c_customer_id
WHERE wi.total_sales > (SELECT AVG(total_sales) FROM FilteredSales)
ORDER BY wi.sales_value DESC
LIMIT 50;
