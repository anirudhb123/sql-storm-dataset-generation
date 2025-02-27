
WITH RankedSales AS (
    SELECT 
        ws.sold_date_sk AS sales_date,
        ws.web_site_sk,
        ws.item_sk,
        SUM(ws.net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.sold_date_sk, ws.web_site_sk, ws.item_sk
),
TopItems AS (
    SELECT 
        web_site_sk,
        item_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
DemographicSales AS (
    SELECT 
        cd.gender,
        cd.education_status,
        SUM(ws.net_paid) AS demographic_sales
    FROM 
        TopItems ti
    JOIN 
        web_sales ws ON ti.item_sk = ws.item_sk AND ti.web_site_sk = ws.web_site_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender, cd.education_status
)
SELECT 
    gender,
    education_status,
    demographic_sales,
    RANK() OVER (ORDER BY demographic_sales DESC) AS sales_rank
FROM 
    DemographicSales
ORDER BY 
    sales_rank;
