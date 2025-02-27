
WITH RECURSIVE top_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, SUM(COALESCE(ss_ext_sales_price, 0)) AS total_sales
    FROM customer
    LEFT JOIN store_sales ON c_customer_sk = ss_customer_sk
    WHERE c_current_addr_sk IS NOT NULL
    GROUP BY c_customer_sk, c_first_name, c_last_name
    HAVING SUM(COALESCE(ss_ext_sales_price, 0)) > 10000
    ORDER BY total_sales DESC
    LIMIT 10
), 
customer_demographics AS (
    SELECT cd_gender, cd_marital_status, cd_education_status, COUNT(*) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY cd_gender, cd_marital_status, cd_education_status
), 
sales_stats AS (
    SELECT 
        ws_bill_cdemo_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_revenue,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cs.total_orders,
    cs.total_revenue,
    cs.avg_profit
FROM 
    top_customers AS c
JOIN 
    customer_demographics AS cd ON c.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_stats AS cs ON c.c_customer_sk = cs.ws_bill_cdemo_sk
ORDER BY 
    cs.total_revenue DESC;
