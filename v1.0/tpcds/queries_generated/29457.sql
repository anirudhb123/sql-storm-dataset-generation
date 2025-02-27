
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
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
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        cs_item_sk,
        cs_sales_price,
        cs_order_number,
        cs_quantity,
        cs_net_profit,
        cs_sold_date_sk
    FROM 
        catalog_sales
    UNION ALL
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ws_sold_date_sk
    FROM 
        web_sales
),
DetailedSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.cs_sales_price,
        sd.cs_order_number,
        sd.cs_quantity,
        sd.cs_net_profit,
        dd.d_date,
        dd.d_day_name,
        dd.d_weekend,
        dd.d_holiday
    FROM 
        SalesData sd
    JOIN 
        date_dim dd ON sd.cs_sold_date_sk = dd.d_date_sk
),
AggregateSales AS (
    SELECT 
        c.c_customer_id,
        ca.full_address,
        SUM(ds.cs_net_profit) AS total_net_profit,
        AVG(ds.cs_sales_price) AS avg_sales_price,
        COUNT(ds.cs_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        DetailedSales ds ON c.c_customer_sk = ds.cs_item_sk
    GROUP BY 
        c.c_customer_id, ca.full_address
)
SELECT 
    customer_id,
    full_address,
    total_net_profit,
    avg_sales_price,
    total_orders,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High-value'
        WHEN total_net_profit > 500 THEN 'Medium-value'
        ELSE 'Low-value' 
    END AS customer_value_segment
FROM 
    AggregateSales
ORDER BY 
    total_net_profit DESC;
