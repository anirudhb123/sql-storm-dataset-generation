
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MIN(ws.ws_sold_date_sk) AS first_purchase_date,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        AVG(ib.ib_upper_bound) AS avg_income
    FROM 
        income_band ib
    GROUP BY 
        ib.ib_income_band_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.first_purchase_date,
        cs.last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.avg_income
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
    JOIN 
        IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    * 
FROM 
    FinalReport
WHERE 
    total_sales > 1000
ORDER BY 
    last_purchase_date DESC;
