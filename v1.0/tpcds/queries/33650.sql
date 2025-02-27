
WITH RECURSIVE customer_tree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ct.level + 1
    FROM customer c
    INNER JOIN customer_tree ct ON c.c_current_addr_sk = ct.c_current_addr_sk
    WHERE ct.level < 5
),
sales_summary AS (
    SELECT ws_bill_customer_sk AS customer_id, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
return_summary AS (
    SELECT sr_customer_sk AS customer_id,
           SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
combined_summary AS (
    SELECT cs.customer_id,
           COALESCE(cs.total_sales, 0) AS total_sales,
           COALESCE(rs.total_returns, 0) AS total_returns,
           (COALESCE(cs.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_sales
    FROM sales_summary cs
    FULL OUTER JOIN return_summary rs ON cs.customer_id = rs.customer_id
),
address_details AS (
    SELECT ca.ca_address_sk AS address_id, 
           ca.ca_city, ca.ca_state, 
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer_address ca
),
final_report AS (
    SELECT ct.c_first_name, ct.c_last_name, ad.full_address, 
           cs.total_sales, cs.total_returns, cs.net_sales,
           ROW_NUMBER() OVER (ORDER BY cs.net_sales DESC) AS sales_rank
    FROM combined_summary cs
    JOIN customer_tree ct ON cs.customer_id = ct.c_customer_sk
    JOIN address_details ad ON ct.c_current_addr_sk = ad.address_id
)
SELECT * FROM final_report
WHERE sales_rank <= 50
ORDER BY net_sales DESC;
