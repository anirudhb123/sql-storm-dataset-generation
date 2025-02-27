
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
Insights AS (
    SELECT 
        ss.c_customer_id,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.hd_income_band_sk
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDemographics cd ON ss.c_customer_id = cd.c_customer_id
)
SELECT 
    i.c_customer_id,
    i.total_quantity,
    i.total_sales,
    i.total_discount,
    cd.count as demographic_count,
    i.cd_gender,
    i.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    Insights i
JOIN 
    income_band ib ON i.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    CustomerDemographics cd ON i.cd_gender = cd.cd_gender AND i.cd_marital_status = cd.cd_marital_status
ORDER BY 
    total_sales DESC;
