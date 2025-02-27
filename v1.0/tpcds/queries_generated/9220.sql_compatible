
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.sales_price,
        ws.ext_discount_amt,
        ws.net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_paid DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
top_sales AS (
    SELECT 
        web_site_sk,
        order_number,
        sales_price,
        ext_discount_amt,
        net_paid
    FROM ranked_sales
    WHERE sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.customer_id,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        SUM(ts.net_paid) AS total_spent
    FROM top_sales ts
    JOIN customer c ON ts.order_number = c.c_customer_sk
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.customer_id, cd.gender, cd.marital_status, cd.education_status
)
SELECT 
    ci.customer_id,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    ci.total_spent,
    CASE 
        WHEN ci.total_spent > 1000 THEN 'High Value'
        WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM customer_info ci
ORDER BY ci.total_spent DESC;
