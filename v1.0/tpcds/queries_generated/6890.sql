
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        di.cd_gender,
        di.cd_marital_status
    FROM customer_sales cs
    JOIN demographic_info di ON cs.c_customer_sk = di.cd_demo_sk
)

SELECT 
    si.cd_gender,
    si.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(si.total_sales) AS avg_sales,
    SUM(si.total_orders) AS total_orders
FROM sales_info si
GROUP BY si.cd_gender, si.cd_marital_status
ORDER BY customer_count DESC
LIMIT 10;
