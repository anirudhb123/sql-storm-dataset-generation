
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MAX(ws.ws_net_paid) AS highest_order_value,
        MIN(ws.ws_net_paid) AS lowest_order_value
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        cs.highest_order_value,
        cs.lowest_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales AS cs
    JOIN 
        CustomerDemographics AS cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS demographic_count,
    AVG(total_sales) AS avg_sales,
    AVG(total_orders) AS avg_orders,
    AVG(avg_order_value) AS avg_order_value,
    MAX(highest_order_value) AS max_highest_order_value,
    MIN(lowest_order_value) AS min_lowest_order_value
FROM 
    SalesSummary
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    demographic_count DESC
LIMIT 10;
