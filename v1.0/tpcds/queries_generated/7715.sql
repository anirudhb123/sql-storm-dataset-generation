
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY c.c_first_name) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),  
SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        RankedCustomers rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    GROUP BY 
        ws.ws_ship_date_sk
),
CustomerDemographics AS (
    SELECT 
        rc.cd_income_band_sk,
        rc.cd_gender,
        rc.cd_marital_status,
        COUNT(*) AS customer_count
    FROM 
        RankedCustomers rc 
    GROUP BY 
        rc.cd_income_band_sk, 
        rc.cd_gender, 
        rc.cd_marital_status
)
SELECT 
    d.d_date AS sales_date, 
    ss.total_sales, 
    ss.total_orders, 
    cd.customer_count,
    cd.cd_income_band_sk,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    date_dim d
LEFT JOIN 
    SalesSummary ss ON d.d_date_sk = ss.ws_ship_date_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_income_band_sk IN (1, 2, 3) -- Filtering for specific income bands
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    sales_date, cd.cd_income_band_sk
LIMIT 1000;
