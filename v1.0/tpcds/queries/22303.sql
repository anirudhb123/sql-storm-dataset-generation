
WITH RECURSIVE Income_CTE AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound,
           CASE 
               WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Unknown'
               WHEN ib_lower_bound < 0 THEN 'Negative Income'
               ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
           END AS income_range
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
), 
Customer_Info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           addr.ca_city,
           addr.ca_state,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
), 
Sales_Summary AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS total_orders,
           MAX(ws.ws_sales_price) AS max_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT ci.c_customer_sk,
       ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       ci.cd_marital_status,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.total_orders, 0) AS total_orders,
       ib.income_range,
       CASE 
           WHEN ss.total_sales = 0 THEN 'No Purchases'
           WHEN ss.total_sales BETWEEN 1 AND 100 THEN 'Low Spender'
           WHEN ss.total_sales BETWEEN 101 AND 500 THEN 'Moderate Spender'
           ELSE 'High Roller'
       END AS spender_category
FROM Customer_Info ci
LEFT JOIN Sales_Summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN Income_CTE ib ON (CASE 
                                WHEN ci.cd_purchase_estimate IS NULL THEN NULL
                                ELSE (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= ci.cd_purchase_estimate AND ib_upper_bound >= ci.cd_purchase_estimate)
                             END) = ib.ib_income_band_sk
WHERE ci.rank <= 5
AND ci.ca_city IS NOT NULL
ORDER BY ci.cd_gender, total_sales DESC, ci.c_last_name;
