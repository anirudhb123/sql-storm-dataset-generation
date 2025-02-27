
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 10000 AND 10005
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.total_orders
    FROM ranked_sales r
    JOIN customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE r.sales_rank <= 10
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        t.total_sales,
        t.total_orders
    FROM top_customers t
    JOIN customer_demographics cd ON t.ws_bill_customer_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(cd.total_sales) AS avg_sales,
        SUM(cd.total_orders) AS total_orders
    FROM customer_demo cd
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    gender,
    marital_status,
    education_status,
    avg_sales,
    total_orders
FROM sales_summary
ORDER BY avg_sales DESC;
