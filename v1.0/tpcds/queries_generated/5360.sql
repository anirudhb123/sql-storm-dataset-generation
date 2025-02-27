
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalReport AS (
    SELECT 
        ss.c_customer_id,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        dem.cd_gender,
        dem.ib_lower_bound,
        dem.ib_upper_bound,
        ss.sales_year,
        ss.sales_month
    FROM 
        SalesSummary ss
    JOIN 
        Demographics dem ON ss.c_customer_id = dem.cd_demo_sk
)
SELECT 
    fr.c_customer_id,
    fr.total_quantity,
    fr.total_sales,
    fr.total_discount,
    fr.cd_gender,
    fr.ib_lower_bound,
    fr.ib_upper_bound,
    fr.sales_year,
    fr.sales_month
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > 5000
ORDER BY 
    fr.sales_year DESC, fr.sales_month DESC, fr.total_sales DESC
LIMIT 100;
