
WITH SalesAggregates AS (
    SELECT 
        d.d_year AS sales_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS average_sale_price,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(SA.total_profit) AS demographic_profit
    FROM 
        SalesAggregates SA
        JOIN customer c ON c.c_customer_sk = (SELECT ws.ws_ship_customer_sk FROM web_sales ws WHERE ws.ws_order_number = SA.total_orders LIMIT 1)
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
TopDemographics AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY demographic_profit DESC) AS rank
    FROM 
        CustomerDemographics
)
SELECT 
    d.sales_year,
    td.cd_gender,
    td.cd_marital_status,
    td.cd_education_status,
    td.demographic_profit
FROM 
    SalesAggregates d
JOIN 
    TopDemographics td ON d.total_orders = (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales WHERE ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_year = d.sales_year) LIMIT 1)
WHERE 
    td.rank <= 5
ORDER BY 
    d.sales_year, td.demographic_profit DESC;
