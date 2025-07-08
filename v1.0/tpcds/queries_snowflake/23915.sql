
WITH RevenueData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS revenue_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3)
    GROUP BY 
        ws_bill_customer_sk
), 

CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 

TopCustomers AS (
    SELECT 
        rd.customer_sk,
        rd.total_revenue,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RevenueData rd
    JOIN 
        CustomerDemographics cd ON rd.customer_sk = cd.c_customer_sk
    WHERE 
        rd.revenue_rank <= 100
)

SELECT 
    tc.customer_sk,
    tc.total_revenue,
    COALESCE(tc.cd_gender, 'Unknown') AS gender,
    COALESCE(tc.cd_marital_status, 'Unknown') AS marital_status,
    COALESCE(tc.cd_education_status, 'Unknown') AS education_status,
    above_avg_profit_orders.above_avg_profit_orders
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.customer_sk)
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT sr_store_sk FROM store_returns WHERE sr_customer_sk = tc.customer_sk ORDER BY sr_returned_date_sk DESC LIMIT 1)
JOIN (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS above_avg_profit_orders
    FROM 
        web_sales 
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales)
    GROUP BY 
        ws_bill_customer_sk
) above_avg_profit_orders ON above_avg_profit_orders.ws_bill_customer_sk = tc.customer_sk
WHERE 
    tc.total_revenue > 1000
ORDER BY 
    tc.total_revenue DESC
LIMIT 50;
