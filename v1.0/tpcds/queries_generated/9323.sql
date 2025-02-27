
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        EXTRACT(YEAR FROM d_date) AS sales_year,
        EXTRACT(MONTH FROM d_date) AS sales_month
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk 
    GROUP BY 
        ws_bill_customer_sk, sales_year, sales_month
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_dep_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
CombinedData AS (
    SELECT 
        sd.ws_bill_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        sd.total_sales,
        sd.total_discount,
        sd.total_orders,
        sd.sales_year,
        sd.sales_month
    FROM 
        SalesData sd
    JOIN 
        CustomerData cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    AVG(cd.total_sales) AS avg_sales,
    SUM(cd.total_sales) AS sum_sales,
    COUNT(DISTINCT cd.ws_bill_customer_sk) AS customer_count,
    SUM(cd.total_orders) AS total_orders,
    SUM(cd.total_discount) AS total_discount
FROM 
    CombinedData cd
JOIN 
    income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    avg_sales DESC, customer_count DESC;
