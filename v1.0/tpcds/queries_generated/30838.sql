
WITH RECURSIVE SalesCTE AS (
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_sales_price, ss_net_paid, 
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(ws_sold_date_sk) - 30 FROM web_sales)
), AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country,
           CASE 
               WHEN ca_state IS NULL THEN 'Unknown State' 
               ELSE ca_state 
           END AS state_info
    FROM customer_address
), ItemInfo AS (
    SELECT i_item_sk, i_item_desc, i_current_price, i_brand
    FROM item
    WHERE i_current_price IS NOT NULL
), CustomerInfo AS (
    SELECT c_customer_sk, c_first_name, c_last_name, DENSE_RANK() OVER (ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_purchase_estimate > 1000
), TotalSales AS (
    SELECT c.c_customer_sk, SUM(s.ss_net_paid) AS total_net_paid
    FROM CustomerInfo c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ts.total_net_paid,
    ia.i_item_desc,
    ia.i_current_price,
    aa.ca_city,
    aa.state_info,
    COALESCE(SUM(ct.ss_quantity), 0) AS total_quantity_sold
FROM CustomerInfo ci
JOIN TotalSales ts ON ci.c_customer_sk = ts.c_customer_sk
JOIN ItemInfo ia ON ia.i_item_sk IN (SELECT ss_item_sk FROM store_sales WHERE ss_net_paid > 10)
LEFT JOIN AddressCTE aa ON ci.c_current_addr_sk = aa.ca_address_sk
LEFT JOIN SalesCTE ct ON ci.c_customer_sk = ct.ss_customer_sk
WHERE ci.purchase_rank <= 10
GROUP BY ci.c_first_name, ci.c_last_name, ts.total_net_paid, ia.i_item_desc, ia.i_current_price, aa.ca_city, aa.state_info
ORDER BY total_quantity_sold DESC, ts.total_net_paid DESC
LIMIT 100;
