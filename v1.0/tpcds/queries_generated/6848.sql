
WITH customer_stats AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_sk) AS total_customers, 
        SUM(CASE WHEN c.c_birth_year < 1985 THEN 1 ELSE 0 END) AS pre_1985_count,
        SUM(CASE WHEN c.c_birth_year BETWEEN 1985 AND 2000 THEN 1 ELSE 0 END) AS between_1985_2000_count,
        SUM(CASE WHEN c.c_birth_year > 2000 THEN 1 ELSE 0 END) AS post_2000_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), 
sales_summary AS (
    SELECT 
        ws.ws_bill_cdemo_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_cdemo_sk
), 
demographic_sales AS (
    SELECT 
        cs.cd_gender, 
        cs.cd_marital_status,
        s.total_sales,
        s.total_orders
    FROM 
        customer_stats cs
    LEFT JOIN 
        sales_summary s ON s.ws_bill_cdemo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = cs.cd_gender AND cd_marital_status = cs.cd_marital_status LIMIT 1)
)

SELECT 
    ds.cd_gender, 
    ds.cd_marital_status, 
    ds.total_sales, 
    ds.total_orders, 
    CONCAT('Total Customers: ', cs.total_customers, 
           '; Pre-1985: ', cs.pre_1985_count, 
           '; 1985-2000: ', cs.between_1985_2000_count, 
           '; Post-2000: ', cs.post_2000_count) AS customer_age_distribution
FROM 
    demographic_sales ds
JOIN 
    customer_stats cs ON ds.cd_gender = cs.cd_gender AND ds.cd_marital_status = cs.cd_marital_status
WHERE 
    ds.total_sales > 1000
ORDER BY 
    ds.total_sales DESC;
