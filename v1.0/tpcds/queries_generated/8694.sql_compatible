
WITH CustomerSales AS (
    SELECT 
        cs.customer_sk,
        SUM(cs.net_profit) AS total_profit,
        COUNT(DISTINCT cs.order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        store_sales cs
    JOIN 
        date_dim d ON cs.sold_date_sk = d.d_date_sk
    GROUP BY 
        cs.customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cs.total_profit,
        cs.order_count,
        cs.last_purchase_date
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    SUM(c.total_profit) AS overall_profit,
    COUNT(c.order_count) AS total_orders,
    COUNT(CASE WHEN d.d_year = 2023 THEN 1 END) AS orders_this_year
FROM 
    CustomerDetails c
JOIN 
    date_dim d ON c.last_purchase_date = d.d_date
WHERE 
    c.total_profit > (SELECT AVG(total_profit) FROM CustomerSales)
GROUP BY 
    c.c_first_name, c.c_last_name, c.ca_city, c.ca_state
ORDER BY 
    overall_profit DESC
LIMIT 10;
