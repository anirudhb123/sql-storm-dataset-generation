
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
IncomeBandSales AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(cs.total_sales) AS total_income_sales
    FROM 
        IncomeBand ib
    JOIN 
        CustomerSales cs ON ib.ib_income_band_sk = cs.cd_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
SalesAnalysis AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        ib.total_income_sales,
        CASE 
            WHEN cs.total_sales >= ib.total_income_sales THEN 'Above Average'
            ELSE 'Below Average'
        END AS sales_comparison
    FROM 
        CustomerSales cs
    JOIN 
        IncomeBandSales ib ON cs.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    sales_analysis.c_first_name,
    sales_analysis.c_last_name,
    sales_analysis.total_sales,
    sales_analysis.sales_comparison
FROM 
    SalesAnalysis sales_analysis
ORDER BY 
    sales_analysis.total_sales DESC
LIMIT 100;
