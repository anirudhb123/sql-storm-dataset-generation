
WITH CustomerPurchaseData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dd.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, dd.d_year
),
IncomeBandAnalysis AS (
    SELECT 
        cp.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.customer_sk) AS customer_count,
        AVG(cp.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics cp
    JOIN 
        customer c ON cp.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        income_band ib ON cp.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cp.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
FinalReport AS (
    SELECT 
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.cd_marital_status,
        sum(cd.total_sales) AS total_sales,
        sum(cd.total_quantity) AS total_quantity,
        ia.customer_count,
        ia.avg_purchase_estimate
    FROM 
        CustomerPurchaseData cp
    JOIN 
        IncomeBandAnalysis ia ON cp.cd_purchase_estimate BETWEEN ia.ib_lower_bound AND ia.ib_upper_bound
    GROUP BY 
        cp.c_first_name, cp.c_last_name, cp.cd_gender, cp.cd_marital_status
)
SELECT * 
FROM FinalReport
ORDER BY total_sales DESC
LIMIT 100;
