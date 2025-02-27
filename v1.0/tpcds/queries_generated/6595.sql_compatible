
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
), IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales
    FROM 
        CustomerSales cs
    JOIN 
        household_demographics hd ON cs.cd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.customer_count,
    ib.avg_sales
FROM 
    IncomeBands ib
ORDER BY 
    ib.avg_sales DESC;
