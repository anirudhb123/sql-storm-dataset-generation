
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                             AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS demographic_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
        AND cd.cd_marital_status IN ('M', 'S')
)
SELECT 
    c.customer_id,
    c.c_first_name,
    c.c_last_name,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    cs.total_sales,
    cs.sales_rank
FROM 
    customer c
LEFT JOIN 
    CustomerDemographics cd ON c.c_customer_sk = cd.c_customer_sk
LEFT JOIN 
    RankedSales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
WHERE 
    cs.total_sales IS NOT NULL
    AND cd.demographic_rank <= 10
ORDER BY 
    cs.total_sales DESC;
