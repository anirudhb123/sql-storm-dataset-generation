
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        CustomerDemographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    r.web_site_id,
    r.total_quantity,
    r.total_sales,
    r.total_discount,
    s.order_count,
    s.total_sales AS demographic_sales,
    s.total_discount AS demographic_discount
FROM 
    RankedSales r
LEFT JOIN 
    SalesByDemographics s ON s.order_count > 0
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;
