
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_product_name, i_current_price, 
           CAST(i_product_name AS VARCHAR(200)) AS full_path
    FROM item
    WHERE i_item_sk IN (SELECT i_item_sk FROM inventory WHERE inv_quantity_on_hand > 0)
    
    UNION ALL
    
    SELECT i.i_item_sk, i.i_product_name, i.i_current_price, 
           CONCAT(ih.full_path, ' > ', i.i_product_name)
    FROM item i
    JOIN ItemHierarchy ih ON i.brand_id = ih.i_item_sk
), 
SalesData AS (
    SELECT ws_sold_date_sk, ws_item_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
MaxSales AS (
    SELECT ws_item_sk, MAX(total_sales) AS max_sales
    FROM SalesData
    GROUP BY ws_item_sk
),
CustomerIncomes AS (
    SELECT hd_income_band_sk, COUNT(c_customer_sk) AS customer_count
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd_income_band_sk
)
SELECT 
    ch.ca_city, 
    AVG(sd.total_sales) AS avg_sales,
    SUM(ci.customer_count) AS total_customers,
    COUNT(DISTINCT ih.full_path) AS item_categories
FROM customer_address ch
LEFT JOIN SalesData sd ON ch.ca_address_sk = sd.ws_bill_addr_sk
LEFT JOIN MaxSales ms ON sd.ws_item_sk = ms.ws_item_sk
LEFT JOIN CustomerIncomes ci ON ci.hd_income_band_sk = ms.ws_item_sk
LEFT JOIN ItemHierarchy ih ON ms.ws_item_sk = ih.i_item_sk
WHERE ch.ca_state = 'CA'
AND (sd.total_sales IS NOT NULL OR ci.customer_count > 0)
GROUP BY ch.ca_city
ORDER BY avg_sales DESC
LIMIT 10;
