
WITH SalesData AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        d_year,
        d_month_seq
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        ws_order_number, d_year, d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F'
),
AggregatedData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(sd.total_sales) AS total_sales,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_first_name, c.c_last_name
)
SELECT 
    first_name,
    last_name,
    total_sales,
    avg_purchase_estimate,
    total_orders
FROM 
    AggregatedData
ORDER BY 
    total_sales DESC
LIMIT 10;
