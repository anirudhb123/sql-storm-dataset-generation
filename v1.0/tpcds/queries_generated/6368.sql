
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cb.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band cb ON hd.hd_income_band_sk = cb.ib_income_band_sk
),
SalesJoin AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.total_profit,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    JOIN 
        Demographics d ON cd.cd_demo_sk = d.cd_demo_sk
)
SELECT 
    sj.cd_gender,
    sj.cd_marital_status,
    COUNT(sj.c_customer_id) AS customer_count,
    AVG(sj.total_sales) AS avg_total_sales,
    SUM(sj.total_orders) AS total_orders,
    SUM(sj.total_profit) AS total_profit
FROM 
    SalesJoin sj
GROUP BY 
    sj.cd_gender, sj.cd_marital_status
ORDER BY 
    total_profit DESC
LIMIT 10;
