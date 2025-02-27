
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
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
Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ts.total_spent,
        ts.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        TotalSales ts ON c.c_customer_sk = ts.customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ts.total_spent > 1000 AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
),
SalesStatistics AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS female_married_customers,
        SUM(ts.total_spent) AS total_revenue
    FROM 
        Customers c
    JOIN 
        customer_address ca ON c.ca_city = ca.ca_city AND c.ca_state = ca.ca_state
    GROUP BY 
        ca.ca_state
)
SELECT 
    ss.ca_state,
    ss.female_married_customers,
    ss.total_revenue,
    RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY ss.female_married_customers DESC) AS customer_rank
FROM 
    SalesStatistics ss
ORDER BY 
    ss.total_revenue DESC;
