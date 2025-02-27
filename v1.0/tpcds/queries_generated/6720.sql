
WITH SalesData AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd 
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk 
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
YearlyPerformance AS (
    SELECT 
        sd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        SUM(sd.total_sales) AS yearly_sales,
        SUM(sd.order_count) AS total_orders,
        COUNT(DISTINCT sd.sales_year) AS active_years
    FROM 
        SalesData sd 
    JOIN 
        customer c ON sd.c_customer_id = c.c_customer_id 
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY 
        sd.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_credit_rating
)
SELECT 
    y.c_customer_id,
    y.yearly_sales,
    y.total_orders,
    y.active_years,
    cd.ib_lower_bound,
    cd.ib_upper_bound
FROM 
    YearlyPerformance y 
JOIN 
    CustomerDemographics cd ON y.c_customer_id = cd.cd_demo_sk
WHERE 
    y.yearly_sales > (SELECT AVG(yearly_sales) FROM YearlyPerformance)
ORDER BY 
    y.yearly_sales DESC
LIMIT 100;
