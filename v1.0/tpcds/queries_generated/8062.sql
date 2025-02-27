
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
), 
TopWebsites AS (
    SELECT 
        web_site_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
), 
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS customer_total_sales
    FROM 
        web_sales w
    JOIN 
        customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        TopWebsites tw ON w.ws_web_site_sk = tw.web_site_sk
    GROUP BY 
        c.c_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cs.customer_total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    SUM(cd.customer_total_sales) AS total_sales
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC;
