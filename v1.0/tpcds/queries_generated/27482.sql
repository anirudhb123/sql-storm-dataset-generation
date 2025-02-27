
WITH CustomerInfo AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        sales_year, sales_month
),
SalesAnalysis AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ms.sales_year,
        ms.sales_month,
        ms.total_sales,
        DENSE_RANK() OVER (PARTITION BY ms.sales_year ORDER BY ms.total_sales DESC) AS sales_rank
    FROM 
        CustomerInfo ci
    JOIN 
        MonthlySales ms ON ci.cd_purchase_estimate < ms.total_sales
)
SELECT 
    c_first_name,
    c_last_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    sales_year,
    sales_month,
    total_sales,
    sales_rank
FROM 
    SalesAnalysis
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_year, sales_month, sales_rank;
