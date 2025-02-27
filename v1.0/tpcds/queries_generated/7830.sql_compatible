
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, d.d_year
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesAnalysis AS (
    SELECT 
        ss.c_customer_id,
        ss.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ib_lower_bound,
        cd.ib_upper_bound,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_profit,
        ss.total_orders
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDemographics cd ON ss.c_customer_id = cd.cd_demo_sk
)
SELECT 
    sa.c_customer_id,
    sa.d_year,
    sa.cd_gender,
    sa.cd_marital_status,
    sa.ib_lower_bound,
    sa.ib_upper_bound,
    sa.total_quantity,
    sa.total_sales,
    sa.avg_net_profit,
    sa.total_orders,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_sales DESC) AS sales_rank
FROM 
    SalesAnalysis sa
WHERE 
    sa.total_sales > 1000
ORDER BY 
    sa.d_year, sales_rank;
