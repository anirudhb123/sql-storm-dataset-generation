
WITH RankedReturns AS (
    SELECT wr_returning_customer_sk,
           wr_item_sk,
           SUM(wr_return_quantity) AS total_returned,
           ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS rn
    FROM web_returns
    GROUP BY wr_returning_customer_sk, wr_item_sk
),
PopularItems AS (
    SELECT ws_item_sk,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING COUNT(DISTINCT ws_order_number) > 50
),
HighValueReturns AS (
    SELECT sr_customer_sk,
           SUM(sr_return_amt_inc_tax) AS total_refund,
           COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
    HAVING SUM(sr_return_amt_inc_tax) > 1000
),
AddressInfo AS (
    SELECT ca_address_sk,
           ca_city,
           ca_state,
           CASE
               WHEN ca_state IN ('CA', 'NY') THEN 'West/East Coast'
               ELSE 'Other Regions'
           END AS region
    FROM customer_address
)
SELECT ci.c_first_name,
       ci.c_last_name,
       ai.ca_city,
       ai.ca_state,
       ai.region,
       COALESCE(hvr.total_refund, 0) AS total_refund,
       COALESCE(hvr.return_count, 0) AS return_count,
       COALESCE(pi.order_count, 0) AS order_count
FROM customer ci
LEFT JOIN HighValueReturns hvr ON ci.c_customer_sk = hvr.sr_customer_sk
JOIN AddressInfo ai ON ci.c_current_addr_sk = ai.ca_address_sk
LEFT JOIN PopularItems pi ON pi.ws_item_sk IN (SELECT wr_item_sk FROM web_returns WHERE wr_returning_customer_sk = ci.c_customer_sk)
WHERE (hi.return_count > 2 OR pi.order_count > 10)
  AND (ai.ca_state IS NOT NULL OR (ci.c_birth_country IS NULL AND ci.c_first_name LIKE 'A%'))
ORDER BY total_refund DESC, ci.c_last_name
FETCH FIRST 100 ROWS ONLY;
