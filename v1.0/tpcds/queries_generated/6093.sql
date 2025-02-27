
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    swd.cd_gender,
    swd.cd_marital_status,
    COUNT(swd.c_customer_id) AS customer_count,
    SUM(swd.total_sales) AS total_sales,
    AVG(swd.avg_order_value) AS avg_order_value
FROM 
    SalesWithDemographics swd
GROUP BY 
    swd.cd_gender,
    swd.cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 10;
