
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS purchase_count,
        AVG(ws.ws_ext_sales_price) AS avg_sales_amount
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cp.total_sales) AS sales_sum,
        AVG(cp.total_sales) AS sales_avg
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS demographic_count,
        SUM(cd.sales_sum) AS total_sales,
        AVG(cd.sales_avg) AS average_purchase
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    sa.cd_gender,
    sa.cd_marital_status,
    sa.cd_education_status,
    sa.demographic_count,
    sa.total_sales,
    sa.average_purchase,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.total_sales DESC;
