
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, 0 AS level 
    FROM customer_address 
    WHERE ca_state = 'CA' 
    UNION ALL 
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_street_name, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk + 1 
    WHERE ca.ca_state = 'CA' 
),
filtered_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20010101 AND 20011231
    GROUP BY ws.ws_sold_date_sk
),
return_summary AS (
    SELECT 
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IS NOT NULL
    GROUP BY wr.wr_returned_date_sk
)

SELECT 
    a.ca_address_id,
    a.ca_street_name,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    s.total_sales,
    r.total_returns,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
FROM address_hierarchy a
LEFT OUTER JOIN filtered_customers f ON f.c_customer_sk = a.ca_address_sk
LEFT JOIN sales_summary s ON s.ws_sold_date_sk = a.ca_address_sk
LEFT JOIN return_summary r ON r.wr_returned_date_sk = s.ws_sold_date_sk
WHERE f.purchase_rank <= 10
AND (a.ca_city LIKE 'San%' OR a.ca_city LIKE 'Los%')
ORDER BY net_sales DESC;
