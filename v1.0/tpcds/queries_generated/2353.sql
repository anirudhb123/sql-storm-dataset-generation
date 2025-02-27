
WITH customer_orders AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ss.ticket_number) AS total_store_sales,
        SUM(ss.net_paid) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        co.c_customer_sk,
        co.total_store_sales,
        co.total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer_orders co
    JOIN customer_demographics cd ON co.c_customer_sk = cd.cd_demo_sk
    WHERE co.total_spent > (
        SELECT AVG(total_spent) FROM customer_orders
    )
),
purchase_days AS (
    SELECT 
        DISTINCT d.d_date_id,
        d.d_year,
        d.d_month,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_store_sales,
    hvc.total_spent,
    hvc.cd_gender,
    hvc.cd_marital_status,
    pd.d_year,
    pd.d_month,
    pd.d_date_id
FROM high_value_customers hvc
FULL OUTER JOIN purchase_days pd ON hvc.c_customer_sk = pd.ws_bill_customer_sk
WHERE pd.d_year IS NOT NULL OR hvc.total_store_sales > 5
ORDER BY hvc.total_spent DESC, hvc.total_store_sales ASC
LIMIT 100;
