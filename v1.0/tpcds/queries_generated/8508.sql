
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        wd.web_site_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        TopWebSites wd ON ws.ws_web_site_sk = wd.web_site_id
    JOIN 
        CustomerDemographics cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    GROUP BY 
        wd.web_site_id, cd.cd_gender
)
SELECT 
    ss.web_site_id,
    ss.cd_gender,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales > 100000 THEN 'High Roller'
        WHEN ss.total_sales BETWEEN 50000 AND 100000 THEN 'Mid Tier'
        ELSE 'Low Tier'
    END AS sales_tier,
    (SELECT COUNT(*) FROM CustomerDemographics) AS total_customers
FROM 
    SalesSummary ss
ORDER BY 
    ss.total_sales DESC;
