
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 10080
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_sales,
        r.order_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RankedSales r
    JOIN 
        CustomerAddresses ca ON r.ws_bill_customer_sk = ca.c_customer_sk
    JOIN 
        CustomerDemographics cd ON r.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        r.rank_sales <= 10
)
SELECT 
    city,
    state,
    country,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    AVG(order_count) AS avg_orders
FROM 
    TopCustomers
GROUP BY 
    city, state, country
ORDER BY 
    customer_count DESC;
