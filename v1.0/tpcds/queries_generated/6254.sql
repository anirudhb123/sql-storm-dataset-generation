
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (1, 2, 3)
    GROUP BY 
        ws.web_site_sk
),
TopSites AS (
    SELECT 
        web_site_sk,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RankedSales
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    ts.web_site_sk,
    ts.total_sales AS sales,
    ts.order_count,
    cd.cd_gender,
    cd.hd_income_band_sk,
    cd.customer_count
FROM 
    TopSites ts
JOIN 
    CustomerDemographics cd ON cd.customer_count > 0
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales DESC, cd.cd_gender, cd.hd_income_band_sk;
