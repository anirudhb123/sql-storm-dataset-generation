
WITH RECURSIVE demographic_trends AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate,
           cd_credit_rating, cd_dep_count,
           ROW_NUMBER() OVER (PARTITION BY cd_demo_sk ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
      AND cd_credit_rating IS NOT NULL
),
customer_sales AS (
    SELECT c.c_customer_sk, 
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
rich_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           d.cd_purchase_estimate, 
           COALESCE(d.cd_gender, 'UNKNOWN') AS gender
    FROM customer c
    JOIN demographic_trends d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.rank = 1 AND d.cd_purchase_estimate > 1000
),
international_sales AS (
    SELECT COUNT(*) AS international_orders, 
           SUM(ws.ws_sales_price) AS total_international_sales
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country IS NOT NULL
      AND ca.ca_country NOT IN ('USA', 'CANADA')
      AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
SELECT 
    rc.c_first_name, rc.c_last_name, rc.gender,
    COALESCE(cs.total_sales, 0) AS total_spent,
    COALESCE(cs.order_count, 0) AS orders_placed,
    is.international_orders,
    is.total_international_sales
FROM rich_customers rc
LEFT JOIN customer_sales cs ON rc.c_customer_sk = cs.c_customer_sk
CROSS JOIN international_sales is
WHERE rc.gender = 'M' OR rc.gender = 'F'
  AND (rc.cd_purchase_estimate BETWEEN 5000 AND 10000 OR rc.cd_purchase_estimate IS NULL)
ORDER BY rc.cd_purchase_estimate DESC, rc.c_last_name ASC
LIMIT 100;
