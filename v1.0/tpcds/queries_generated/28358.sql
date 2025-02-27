
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
),
MonthlyBenchmark AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ctr.c_customer_id) AS customer_count,
        SUM(ctr.total_spent) AS total_revenue,
        AVG(ctr.total_spent) AS average_spent
    FROM date_dim d
    LEFT JOIN CustomerDetails ctr ON d.d_date_sk IN (
        SELECT ws.ws_sold_date_sk
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c)
    )
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    d.d_year,
    d.d_month_seq,
    mb.customer_count,
    mb.total_revenue,
    mb.average_spent,
    RANK() OVER (ORDER BY mb.total_revenue DESC) AS revenue_rank
FROM MonthlyBenchmark mb
JOIN date_dim d ON mb.d_year = d.d_year AND mb.d_month_seq = d.d_month_seq
ORDER BY d.d_year, d.d_month_seq;
