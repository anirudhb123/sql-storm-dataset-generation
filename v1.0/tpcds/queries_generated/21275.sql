
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) as city_rank
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales, COUNT(ws_order_number) AS sales_count
    FROM web_sales
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT cs_item_sk, cs_ext_sales_price, cs_ext_discount_amt, cs_net_profit
    FROM catalog_sales
    WHERE cs_sales_price IS NOT NULL AND cs_sales_price > (
        SELECT AVG(ws_net_paid) 
        FROM web_sales 
        WHERE ws_ship_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 6) 
          AND ws_net_paid > 0
    )
),
CustomerProfile AS (
    SELECT cd_gender, COUNT(c_customer_sk) AS customer_count, 
           AVG(cd_purchase_estimate) AS avg_estimate,
           COUNT(DISTINCT c_current_addr_sk) AS address_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
)
SELECT 
    A.ca_city, 
    A.ca_state, 
    A.ca_zip,
    S.total_sales,
    S.sales_count,
    CASE 
        WHEN S.total_sales IS NULL THEN 'No Sales'
        WHEN S.total_sales > 1000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category,
    CP.customer_count,
    CP.avg_estimate,
    CP.address_count
FROM AddressCTE A
LEFT JOIN SalesCTE S ON A.ca_address_sk = S.ws_item_sk
FULL OUTER JOIN CustomerProfile CP ON A.city_rank = (SELECT MIN(city_rank) FROM AddressCTE WHERE ca_state = A.ca_state)
WHERE 
    (A.ca_state IS NOT NULL OR A.ca_zip IS NOT NULL)
    AND (CP.customer_count > (
        SELECT COALESCE(MAX(customer_count), 0) FROM CustomerProfile WHERE avg_estimate < 5000
    ) OR CP.avg_estimate IS NULL)
ORDER BY A.ca_city, S.total_sales DESC;
