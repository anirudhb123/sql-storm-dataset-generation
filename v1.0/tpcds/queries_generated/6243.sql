
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        DATE(d.d_date) AS sale_date,
        sm.sm_type AS ship_mode,
        cd.cd_gender AS customer_gender,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_order_number, sale_date, ship_mode, customer_gender, ib.ib_income_band_sk
    ORDER BY 
        total_sales DESC
)
SELECT 
    sale_date,
    ship_mode,
    COUNT(DISTINCT ws_order_number) AS order_count,
    SUM(total_sales) AS total_sales_amount,
    SUM(total_tax) AS total_tax_amount,
    AVG(unique_customers) AS avg_unique_customers,
    customer_gender,
    income_band_sk
FROM 
    SalesData
GROUP BY 
    sale_date, ship_mode, customer_gender, income_band_sk
ORDER BY 
    sale_date, total_sales_amount DESC;
