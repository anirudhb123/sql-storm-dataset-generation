
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                CustomerSales
        )
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
SalesWithDemographics AS (
    SELECT 
        hs.c_customer_sk,
        hs.c_first_name,
        hs.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM 
        HighSpenders hs
    LEFT JOIN 
        CustomerDemographics cd ON hs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    swd.c_customer_sk,
    swd.c_first_name,
    swd.c_last_name,
    swd.cd_gender,
    COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound,
    SUM(ws.ws_net_profit) AS net_profit
FROM 
    SalesWithDemographics swd
LEFT JOIN 
    household_demographics hhd ON swd.c_customer_sk = hhd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hhd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    web_sales ws ON swd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    swd.c_customer_sk, swd.c_first_name, swd.c_last_name, swd.cd_gender, ib.ib_upper_bound
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    net_profit DESC;
