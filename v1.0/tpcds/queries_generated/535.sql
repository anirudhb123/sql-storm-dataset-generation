
WITH DateSales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Female'
    END AS gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(d.total_sales) AS total_sales,
    SUM(cd.customer_count) AS total_customers,
    AVG(d.total_sales) OVER (PARTITION BY cd.cd_marital_status) AS avg_sales_per_marital_status
FROM 
    DateSales d
FULL OUTER JOIN 
CustomerDemographics cd ON 1=1
JOIN 
    income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING 
    SUM(d.total_sales) IS NOT NULL
ORDER BY 
    total_sales DESC;
