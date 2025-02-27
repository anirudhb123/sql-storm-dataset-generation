
WITH top_customers AS (
    SELECT c.c_customer_id, SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 4 LIMIT 1) 
            AND 
            (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 LIMIT 1)
    GROUP BY c.c_customer_id
    ORDER BY total_spent DESC
    LIMIT 10
), 
customer_details AS (
    SELECT cust.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city
    FROM top_customers cust
    JOIN customer_demographics cd ON cust.c_customer_id = cd.cd_demo_sk
    JOIN customer_address ca ON cust.c_customer_id = ca.ca_address_id
), 
sales_summary AS (
    SELECT cu.ca_city, COUNT(DISTINCT cu.c_customer_id) AS customer_count, SUM(ws.ws_net_paid) AS total_revenue
    FROM customer_details cu
    JOIN web_sales ws ON cu.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY cu.ca_city
)
SELECT ss.ca_city, ss.customer_count, ss.total_revenue,
       RANK() OVER (ORDER BY ss.total_revenue DESC) AS rank_by_revenue
FROM sales_summary ss
WHERE ss.total_revenue > 10000
ORDER BY ss.total_revenue DESC;
