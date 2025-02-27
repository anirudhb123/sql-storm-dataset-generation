
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_gender, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS average_sales,
        MAX(cs.total_sales) AS max_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    cd.cd_gender,
    COUNT(cd.cd_demo_sk) AS demographic_count,
    SUM(cd.customer_count) AS total_customers,
    AVG(cd.average_sales) AS avg_sales_per_demo,
    MAX(cd.max_sales) AS peak_sales_per_demo
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender
ORDER BY 
    cd.cd_gender;
