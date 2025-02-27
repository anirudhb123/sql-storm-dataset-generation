
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023
    AND 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ts.total_sales) AS total_sales_by_demo
    FROM 
        TopSales ts
    JOIN 
        customer c ON ts.web_site_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales_by_demo,
    RANK() OVER (ORDER BY total_sales_by_demo DESC) AS sales_rank
FROM 
    CustomerDemographics
ORDER BY 
    total_sales_by_demo DESC;
