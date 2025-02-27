
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.first_purchase_date,
    cs.last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound,
    DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk 
WHERE 
    cs.total_sales > 1000
ORDER BY 
    sales_rank;
