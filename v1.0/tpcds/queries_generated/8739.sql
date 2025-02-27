
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2410 AND 2430 -- Date range for sales
    GROUP BY 
        c.c_customer_id
), TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_sales
    FROM 
        customer_demographics cd
    JOIN 
        TopCustomers tc ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
)
SELECT 
    cd.cd_gender,
    COUNT(*) AS num_top_customers,
    AVG(cd.total_sales) AS avg_sales,
    MAX(cd.total_sales) AS max_sales
FROM 
    CustomerDemographics cd
WHERE 
    cd.total_sales > 1000 -- Filter based on sales
GROUP BY 
    cd.cd_gender
ORDER BY 
    num_top_customers DESC;
