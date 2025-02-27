
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2020
    GROUP BY 
        c.c_customer_id, d.d_year
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.dep_count,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value
    FROM 
        customer_demographics cd
    JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk)
    JOIN 
        sales_summary cs ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk)
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(cd.total_sales) AS avg_sales,
    AVG(cd.total_orders) AS avg_orders,
    AVG(cd.avg_order_value) AS avg_order_value
FROM 
    customer_demographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    avg_sales DESC;
