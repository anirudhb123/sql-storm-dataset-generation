
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_qty AS sold_quantity,
        ws.ws_ext_sales_price AS total_sales,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sales_month,
        ci.full_name
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        dd.d_year = 2023
),
AggregatedSales AS (
    SELECT 
        sales_month,
        COUNT(DISTINCT full_name) AS unique_customers,
        SUM(sold_quantity) AS total_quantity_sold,
        SUM(total_sales) AS total_sales_amount
    FROM 
        SalesData
    GROUP BY 
        sales_month
)
SELECT 
    sales_month,
    unique_customers,
    total_quantity_sold,
    total_sales_amount,
    ROUND(total_sales_amount / NULLIF(total_quantity_sold, 0), 2) AS avg_sales_per_item
FROM 
    AggregatedSales
ORDER BY 
    sales_month;
