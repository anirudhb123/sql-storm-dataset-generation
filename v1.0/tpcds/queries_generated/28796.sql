
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_sold_date_sk) AS active_days
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
GenderDistribution AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
CustomerSales AS (
    SELECT 
        ci.full_name,
        ci.c_birth_country,
        ci.cd_gender,
        sd.total_profit,
        sd.total_orders,
        gd.total_customers
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
    JOIN 
        GenderDistribution gd ON ci.cd_gender = gd.cd_gender
)
SELECT 
    cs.full_name,
    cs.c_birth_country,
    cs.cd_gender,
    COALESCE(cs.total_profit, 0) AS total_profit,
    COALESCE(cs.total_orders, 0) AS total_orders,
    gd.total_customers AS gender_based_customer_count
FROM 
    CustomerSales cs
LEFT JOIN 
    GenderDistribution gd ON cs.cd_gender = gd.cd_gender
ORDER BY 
    cs.total_profit DESC, cs.total_orders DESC;
