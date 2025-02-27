
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d.d_date_sk FROM date_dim AS d WHERE d.d_date = '2023-01-01') 
                               AND (SELECT d.d_date_sk FROM date_dim AS d WHERE d.d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.order_count,
        cs.avg_quantity_per_order,
        cs.c_customer_id
    FROM 
        CustomerSales AS cs
    JOIN 
        customer_demographics AS cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer AS c WHERE c.c_customer_id = cs.c_customer_id)
),
IncomeDistribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(cd.total_sales) AS avg_sales_per_customer
    FROM 
        CustomerDemographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON (hd.hd_demo_sk = (SELECT c.c_current_hdemo_sk FROM customer AS c WHERE c.c_customer_id = cd.c_customer_id))
    LEFT JOIN 
        income_band AS ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.customer_count,
    id.avg_sales_per_customer
FROM 
    IncomeDistribution AS id
JOIN 
    income_band AS ib ON id.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
