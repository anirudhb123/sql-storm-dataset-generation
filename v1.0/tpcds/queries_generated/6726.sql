
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS distinct_ship_dates,
        d.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.total_profit) AS total_profit,
        AVG(ss.avg_order_value) AS avg_order_value,
        COUNT(ss.order_count) AS total_orders
    FROM 
        customer_demographics cd
    LEFT JOIN 
        SalesSummary ss ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS customer_count,
        SUM(cd.total_profit) AS profit_generated,
        AVG(cd.avg_order_value) AS avg_order_value_per_customer
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.customer_count,
    tc.profit_generated,
    tc.avg_order_value_per_customer
FROM 
    TopCustomers tc
ORDER BY 
    profit_generated DESC, customer_count DESC;
