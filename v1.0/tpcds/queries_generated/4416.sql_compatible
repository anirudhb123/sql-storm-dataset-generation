
WITH AddressCount AS (
    SELECT ca_state, COUNT(DISTINCT ca_address_id) AS unique_addresses
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT cd.gender, 
           SUM(CASE WHEN c.c_birth_year < 2000 THEN 1 ELSE 0 END) AS count_young_customers,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.gender
),
SalesData AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_ext_sales_price) AS total_sales, 
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnData AS (
    SELECT cr_refunded_customer_sk AS customer_sk,
           COUNT(DISTINCT cr_order_number) AS total_returns,
           SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_refunded_customer_sk
)
SELECT ac.ca_state,
       cs.gender,
       SUM(sd.total_sales) AS state_sales,
       SUM(rd.total_returns) AS total_returns,
       AVG(cs.avg_purchase_estimate) AS avg_estimate,
       COALESCE(NULLIF(SUM(sd.total_orders), 0), 1) AS adjusted_order_count,
       CASE 
           WHEN SUM(sd.total_sales) > 100000 THEN 'High Sales'
           WHEN SUM(sd.total_sales) BETWEEN 50000 AND 100000 THEN 'Medium Sales'
           ELSE 'Low Sales'
       END AS sales_category
FROM AddressCount ac
LEFT JOIN CustomerStats cs ON ac.ca_state = (
    SELECT ca_state
    FROM customer_address
    WHERE ca_address_sk = c.c_current_addr_sk
) 
LEFT JOIN SalesData sd ON sd.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN ReturnData rd ON rd.customer_sk = c.c_customer_sk
JOIN customer c ON c.c_current_cdemo_sk = cs.gender
GROUP BY ac.ca_state, cs.gender
ORDER BY ac.ca_state, cs.gender;
