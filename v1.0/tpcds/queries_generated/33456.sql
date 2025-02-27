
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_ext_sales_price) > 0
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_sales,
        ss.total_orders,
        ss.sales_rank
    FROM sales_summary ss
    JOIN customer c ON ss.c_customer_sk = c.c_customer_sk
    WHERE ss.sales_rank <= 10
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT tc.c_customer_sk) AS customer_count,
        AVG(ss.total_sales) AS avg_sales_per_customer
    FROM top_customers tc
    JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
final_report AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.customer_count,
        d.avg_sales_per_customer,
        CASE 
            WHEN d.cd_purchase_estimate > 500 THEN 'High Value'
            WHEN d.cd_purchase_estimate BETWEEN 300 AND 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM demographics d
)
SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.value_category,
    SUM(fr.customer_count) AS total_customers,
    AVG(fr.avg_sales_per_customer) AS average_sales
FROM final_report fr
GROUP BY fr.cd_gender, fr.cd_marital_status, fr.value_category
ORDER BY total_customers DESC
LIMIT 20;
