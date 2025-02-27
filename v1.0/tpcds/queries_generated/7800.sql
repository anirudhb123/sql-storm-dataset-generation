
WITH RankedSales AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        ) - 30 AND (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales
    FROM 
        customer c
    INNER JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_sales
    FROM 
        customer_demographics cd
    INNER JOIN 
        TopCustomers tc ON cd.cd_demo_sk = tc.c_customer_id
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS num_customers,
    AVG(cd.total_sales) AS avg_sales
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    num_customers DESC;
