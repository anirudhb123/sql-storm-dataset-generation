
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 2000
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_quantity,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
customer_info AS (
    SELECT 
        tc.c_customer_id,
        tc.total_quantity,
        tc.total_sales,
        tc.order_count,
        CASE 
            WHEN cd.cd_income_band_sk IS NULL THEN 'No Income Band'
            ELSE CONCAT('Income Band ', cd.cd_income_band_sk)
        END AS income_band,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
    WHERE 
        tc.sales_rank <= 10
)
SELECT 
    city.ca_city,
    SUM(ci.total_sales) AS total_sales_by_city,
    COUNT(ci.c_customer_id) AS customer_count,
    AVG(ci.total_quantity) AS avg_quantity_per_customer
FROM 
    customer_info ci
JOIN 
    customer_address ca ON ci.c_customer_id = ca.ca_address_id
LEFT JOIN 
    date_dim d ON d.d_date = CURRENT_DATE
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
    AND ci.total_quantity IS NOT NULL
GROUP BY 
    city.ca_city
HAVING 
    SUM(ci.total_sales) > 1000
ORDER BY 
    total_sales_by_city DESC
LIMIT 5;
