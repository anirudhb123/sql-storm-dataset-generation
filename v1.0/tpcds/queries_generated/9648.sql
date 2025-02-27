
WITH customer_order_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT s.ss_ticket_number) AS total_orders,
        SUM(s.ss_ext_sales_price) AS total_spent,
        AVG(s.ss_net_profit) AS average_profit
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    AND c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY c.c_customer_id
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cos.c_customer_id) AS customer_count,
        SUM(cos.total_spent) AS total_revenue,
        AVG(cos.average_profit) AS avg_profit_per_customer
    FROM customer_order_summary cos
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
sales_trends AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY d.d_year
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_revenue,
    ds.avg_profit_per_customer,
    st.d_year,
    st.total_sales,
    st.total_orders
FROM demographic_summary ds
JOIN sales_trends st ON ds.customer_count > 50
ORDER BY ds.total_revenue DESC, st.d_year ASC
LIMIT 10;
