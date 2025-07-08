
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 1 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 12 ORDER BY d_date_sk DESC LIMIT 1)
    GROUP BY 
        c.c_customer_id
),
IncomeDemographics AS (
    SELECT 
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(cd.cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_profit,
        id.cd_gender,
        id.ib_lower_bound,
        id.ib_upper_bound
    FROM 
        CustomerSales cs
    JOIN 
        IncomeDemographics id ON cs.c_customer_id IN (SELECT c_customer_id FROM customer WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = id.cd_gender))
)
SELECT 
    sa.cd_gender,
    sa.ib_lower_bound,
    sa.ib_upper_bound,
    COUNT(sa.c_customer_id) AS customer_count,
    AVG(sa.total_sales) AS avg_sales,
    SUM(sa.order_count) AS total_orders,
    SUM(sa.avg_profit) AS total_avg_profit
FROM 
    SalesAnalysis sa
GROUP BY 
    sa.cd_gender, sa.ib_lower_bound, sa.ib_upper_bound
ORDER BY 
    sa.cd_gender, sa.ib_lower_bound;
