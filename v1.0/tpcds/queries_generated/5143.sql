
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_moy IN (11, 12) -- November and December
    GROUP BY 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(cp.c_customer_id) AS customer_count,
        SUM(cp.total_sales) AS total_sales,
        SUM(cp.total_discount) AS total_discount
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    cd.total_sales,
    cd.total_discount,
    ROUND(cd.total_sales / NULLIF(cd.customer_count, 0), 2) AS avg_sales_per_customer,
    ROUND(cd.total_discount / NULLIF(cd.customer_count, 0), 2) AS avg_discount_per_customer
FROM 
    CustomerDemographics cd
ORDER BY 
    total_sales DESC;
