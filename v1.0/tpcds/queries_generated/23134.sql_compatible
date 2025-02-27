
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
    FROM customer_address ca
    INNER JOIN AddressCTE cte ON ca.ca_city = cte.ca_city AND ca.ca_state <> cte.ca_state
),
DemographicStats AS (
    SELECT cd_gender, 
           COUNT(DISTINCT cd_demo_sk) AS total_demos, 
           SUM(cd_dep_count) AS total_deps,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           COUNT(CASE WHEN cd_credit_rating = 'Excellent' THEN 1 END) AS excellent_credit
    FROM customer_demographics
    GROUP BY cd_gender
),
SalesSummary AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           SUM(ws_quantity) AS total_quantity,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY ws_sold_date_sk, ws_item_sk
),
StoreReturnsSummary AS (
    SELECT sr_item_sk,
           COUNT(*) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT d.cd_gender,
       d.total_demos,
       d.total_deps,
       d.avg_purchase_estimate,
       d.excellent_credit,
       s.total_sales,
       s.total_quantity,
       COALESCE(r.total_returns, 0) AS total_returns,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       CASE 
           WHEN d.avg_purchase_estimate IS NULL THEN 'No estimate'
           WHEN s.total_sales > 10000 AND COALESCE(r.total_returns, 0) > 0 THEN 'High Sales, Some Returns'
           ELSE 'Normal Sales'
       END AS sales_category
FROM DemographicStats d
LEFT JOIN SalesSummary s ON d.total_demos > 0
LEFT JOIN StoreReturnsSummary r ON s.ws_item_sk = r.sr_item_sk
WHERE d.total_demos > 50
AND EXISTS (
    SELECT 1
    FROM AddressCTE a
    WHERE a.ca_country = 'USA'
      AND a.ca_city LIKE 'New%'
)
ORDER BY d.total_demos DESC, s.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
