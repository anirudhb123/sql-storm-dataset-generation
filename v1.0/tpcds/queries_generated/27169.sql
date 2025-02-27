
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
AggregatedSales AS (
    SELECT 
        DATE_FORMAT(d.d_date, '%Y-%m') AS sales_month,
        SUM(sd.total_profit) AS monthly_profit,
        SUM(sd.total_orders) AS monthly_orders
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON sd.d_date = d.d_date
    GROUP BY 
        DATE_FORMAT(d.d_date, '%Y-%m')
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.c_email_address,
    fc.full_address,
    fc.ca_city,
    fc.ca_state,
    fc.ca_zip,
    asales.sales_month,
    asales.monthly_profit,
    asales.monthly_orders
FROM 
    FilteredCustomers fc
JOIN 
    AggregatedSales asales ON asales.sales_month = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
ORDER BY 
    asales.monthly_profit DESC
LIMIT 10;
