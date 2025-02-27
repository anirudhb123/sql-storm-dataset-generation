
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    AND 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)

SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    cs.average_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
