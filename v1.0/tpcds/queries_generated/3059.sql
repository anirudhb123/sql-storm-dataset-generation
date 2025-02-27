
WITH customer_summary AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           cd.cd_credit_rating, 
           ca.ca_city, 
           ca.ca_state,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) as state_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT c.c_customer_id, 
           SUM(ws.ws_ext_sales_price) as total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_ext_sales_price) > 5000
),
item_sales AS (
    SELECT i.i_item_id, 
           SUM(ws.ws_quantity) as total_sales_quantity, 
           AVG(ws.ws_sales_price) as avg_sales_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
    GROUP BY i.i_item_id
)
SELECT cs.c_customer_id, 
       cs.cd_gender, 
       cs.cd_marital_status, 
       cs.ca_city, 
       cs.ca_state, 
       cs.state_rank, 
       tc.total_sales AS customer_total_sales, 
       COALESCE(is.total_sales_quantity, 0) AS item_sales_quantity, 
       COALESCE(is.avg_sales_price, 0) AS item_avg_price,
       CASE 
           WHEN cs.cd_gender = 'M' AND cs.cd_purchase_estimate > 1000 THEN 'High Value User'
           WHEN cs.cd_gender = 'F' THEN 'Female User'
           ELSE 'Other'
       END AS user_segment
FROM customer_summary cs
LEFT JOIN top_customers tc ON cs.c_customer_id = tc.c_customer_id
LEFT JOIN item_sales is ON tc.total_sales > 1000 AND is.total_sales_quantity > 10
WHERE cs.state_rank <= 5
ORDER BY cs.ca_state, tc.total_sales DESC, cs.c_customer_id;
