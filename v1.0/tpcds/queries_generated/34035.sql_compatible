
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        ws.bill_customer_sk
    HAVING 
        SUM(ws.ext_sales_price) > 1000
), 
DemographicData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), 
TopDemographics AS (
    SELECT 
        dd.cd_gender,
        dd.cd_marital_status,
        SUM(dd.customer_count) AS demographic_count
    FROM 
        DemographicData dd
    GROUP BY 
        dd.cd_gender, dd.cd_marital_status
)
SELECT 
    sd.bill_customer_sk,
    sd.total_sales,
    sd.order_count,
    td.cd_gender,
    td.cd_marital_status,
    td.demographic_count
FROM 
    SalesData sd
LEFT JOIN 
    TopDemographics td ON sd.bill_customer_sk = td.cd_gender
WHERE 
    sd.rank <= 10 AND 
    (td.cd_marital_status IS NULL OR td.cd_marital_status = 'M')
ORDER BY 
    sd.total_sales DESC;
