
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_current_year = 'Y'
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_sk, 
        web_site_id, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesByDemographic AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    tw.web_site_id,
    tw.total_sales AS top_sales,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    sd.total_sales AS demographic_sales
FROM 
    TopWebSites tw
LEFT JOIN 
    SalesByDemographic sd ON sd.total_sales > 0
ORDER BY 
    tw.total_sales DESC, sd.total_sales DESC;
