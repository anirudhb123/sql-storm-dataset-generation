
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CASE 
            WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'VIP'
            WHEN SUM(ws.ws_ext_sales_price) BETWEEN 5000 AND 10000 THEN 'Premium'
            ELSE 'Standard'
        END AS customer_segment
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
),
customer_segments AS (
    SELECT 
        hvc.c_customer_id,
        hvc.total_sales,
        hvc.order_count,
        hvc.customer_segment,
        cd.ca_city,
        cd.ca_state,
        ROW_NUMBER() OVER (PARTITION BY hvc.customer_segment ORDER BY hvc.total_sales DESC) AS segment_rank
    FROM high_value_customers hvc
    LEFT JOIN customer_address cd ON hvc.c_customer_id = cd.ca_address_id
),
top_customers AS (
    SELECT c.c_customer_id, 
           cs.total_sales, 
           cs.customer_segment,
           cs.order_count,
           COALESCE(cs.ca_city, 'Unknown') AS city, 
           COALESCE(cs.ca_state, 'Unknown') AS state,
           DENSE_RANK() OVER (PARTITION BY cs.customer_segment ORDER BY cs.total_sales DESC) AS dr
    FROM customer_segments cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    t.customer_segment,
    COUNT(*) AS customer_count,
    AVG(t.total_sales) AS avg_sales,
    MAX(t.total_sales) AS max_sales,
    MIN(t.total_sales) AS min_sales,
    LISTAGG(t.city, ', ') AS cities,
    LISTAGG(t.state, ', ') AS states
FROM top_customers t
WHERE t.dr <= 10
GROUP BY t.customer_segment
ORDER BY customer_count DESC;
