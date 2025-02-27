
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
DemographicsData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ib.ib_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesByDemographics AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_credit_rating,
        SUM(cs.total_sales) AS sales_sum,
        AVG(cs.total_orders) AS average_orders,
        AVG(cs.avg_profit) AS average_profit
    FROM 
        CustomerSales cs
    JOIN 
        DemographicsData d ON cs.c_customer_id IN (
            SELECT c.c_customer_id 
            FROM customer c 
            WHERE c.c_current_cdemo_sk IS NOT NULL
        )
    GROUP BY 
        d.cd_gender, d.cd_marital_status, d.cd_credit_rating
)
SELECT 
    gender,
    marital_status,
    credit_rating,
    sales_sum,
    average_orders,
    average_profit
FROM 
    SalesByDemographics
WHERE 
    sales_sum > 10000
ORDER BY 
    sales_sum DESC;
