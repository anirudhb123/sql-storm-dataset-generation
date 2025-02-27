
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
    UNION ALL
    SELECT cs_item_sk, SUM(cs_quantity) AS total_sales
    FROM catalog_sales
    WHERE cs_item_sk IN (SELECT ws_item_sk FROM SalesHierarchy)
    GROUP BY cs_item_sk
),
CustomerReturnStats AS (
    SELECT sr_customer_sk,
           COUNT(DISTINCT sr_ticket_number) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount,
           AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
OrderedCustomerDemographics AS (
    SELECT cd_demo_sk,
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank_by_purchase
    FROM customer_demographics
),
ItemAverageSales AS (
    SELECT i_item_sk,
           AVG(ws_sales_price) AS avg_sales_price,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    JOIN item ON ws_item_sk = i_item_sk
    WHERE ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')
    GROUP BY i_item_sk
)
SELECT ca.city,
       COUNT(DISTINCT c.c_customer_id) AS unique_customers,
       SUM(COALESCE(cr.total_return_amount, 0)) AS total_return_amount,
       SUM(COALESCE(ia.avg_sales_price * ia.order_count, 0)) AS total_sales_value,
       CASE 
           WHEN COUNT(DISTINCT c.c_customer_id) > 0 THEN (SUM(COALESCE(cr.total_return_amount, 0)) / COUNT(DISTINCT c.c_customer_id))
           ELSE 0
       END AS avg_return_amount_per_customer
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerReturnStats AS cr ON cr.sr_customer_sk = c.c_customer_sk
LEFT JOIN ItemAverageSales AS ia ON ia.i_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE EXISTS (
    SELECT 1
    FROM SalesHierarchy AS sh
    WHERE sh.ws_item_sk = ia.i_item_sk
)
GROUP BY ca.city
HAVING SUM(COALESCE(cr.total_return_amount, 0)) > 1000
ORDER BY unique_customers DESC;
