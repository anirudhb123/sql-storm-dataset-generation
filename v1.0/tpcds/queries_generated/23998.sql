
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, 
           ca_address_id, 
           ca_city, 
           ca_state, 
           ca_country, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
    UNION ALL
    SELECT ca_address_sk, 
           ca_address_id, 
           ca_city, 
           ca_state, 
           ca_country, 
           rn + 1
    FROM AddressCTE
    WHERE rn < 5
),
DemographicsCTE AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           COUNT(*) OVER (PARTITION BY cd_gender) AS gender_count
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
FilteredSales AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price - ws_ext_discount_amt) AS total_sales_price,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
    GROUP BY ws_item_sk
),
RankedSales AS (
    SELECT ws_item_sk,
           total_sales_price,
           order_count,
           RANK() OVER (ORDER BY total_sales_price DESC) AS sales_rank
    FROM FilteredSales
)
SELECT 
    a.ca_address_id,
    d.cd_gender,
    d.gender_count,
    r.ws_item_sk,
    r.total_sales_price,
    r.order_count,
    CASE 
        WHEN r.total_sales_price IS NULL THEN 'No Sales'
        ELSE CASE 
            WHEN r.total_sales_price > 1000 THEN 'High Sales'
            WHEN r.total_sales_price BETWEEN 500 AND 1000 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END
    END AS sales_category
FROM AddressCTE a
LEFT JOIN DemographicsCTE d ON a.rn = d.cd_demo_sk % 5
LEFT JOIN RankedSales r ON a.ca_address_sk = r.ws_item_sk
WHERE (a.ca_country IS NOT NULL OR a.ca_country = 'USA')
AND (d.cd_marital_status = 'M' OR d.cd_marital_status IS NULL)
ORDER BY a.ca_city, d.gender_count DESC, r.total_sales_price DESC
LIMIT 50;
