
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
),
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_income_band,
        SUM(ss.total_sales) AS total_sales_by_demo
    FROM 
        customer_demographics cd
    JOIN 
        SalesSummary ss ON cd.cd_demo_sk = ss.c_customer_id
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_income_band
)
SELECT 
    di.cd_gender,
    di.cd_income_band,
    SUM(di.total_sales_by_demo) AS total_sales,
    AVG(di.total_sales_by_demo) AS avg_sales_per_cust,
    COUNT(DISTINCT di.cd_demo_sk) AS customer_count
FROM 
    DemographicInfo di
GROUP BY 
    di.cd_gender, di.cd_income_band
ORDER BY 
    total_sales DESC
LIMIT 10;
