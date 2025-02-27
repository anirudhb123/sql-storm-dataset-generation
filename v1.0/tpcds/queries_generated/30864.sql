
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_county, ca_state, ca_zip, 0 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_county, ca.ca_state, ca.ca_zip, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_county = ah.ca_county 
    WHERE ah.level < 2
),
customer_analysis AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           ca.ca_city, ca.ca_county, ca.ca_state, ca.ca_zip,
           CASE WHEN cd.cd_purchase_estimate > 1000 THEN 'High' 
                WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium' 
                ELSE 'Low' END AS purchase_level,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_paid_inc_tax) > 500
),
returns_summary AS (
    SELECT cr_returning_customer_sk, 
           SUM(cr_net_loss) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
final_summary AS (
    SELECT ca.ca_city, ca.ca_county, ca.ca_state, ca.ca_zip,
           COUNT(DISTINCT ca.ca_address_sk) AS address_count,
           SUM(coalesce(cs.total_sales, 0)) AS total_sales,
           SUM(coalesce(rs.total_returns, 0)) AS total_returns
    FROM customer_analysis ca
    LEFT JOIN sales_summary cs ON ca.c_customer_sk = cs.ws_bill_customer_sk
    LEFT JOIN returns_summary rs ON ca.c_customer_sk = rs.cr_returning_customer_sk
    GROUP BY ca.ca_city, ca.ca_county, ca.ca_state, ca.ca_zip
)
SELECT f.ca_city, f.ca_county, f.ca_state, f.ca_zip,
       f.address_count, f.total_sales,
       f.total_returns, 
       CASE WHEN f.total_sales > f.total_returns THEN 'Profit' 
            ELSE 'Loss' END AS profit_loss_status
FROM final_summary f
WHERE f.total_sales IS NOT NULL
ORDER BY f.total_sales DESC, f.total_returns ASC;
