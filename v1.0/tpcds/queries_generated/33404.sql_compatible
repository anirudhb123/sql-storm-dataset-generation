
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
),
RankedSales AS (
    SELECT 
        sh.c_customer_id,
        sh.cd_gender,
        sh.total_sales,
        ROW_NUMBER() OVER (PARTITION BY sh.cd_gender ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band ib
),
CustomerIncome AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.total_sales,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        RankedSales cs
    JOIN 
        IncomeBands ib ON cs.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.total_sales,
    CASE 
        WHEN ci.total_sales < ci.ib_lower_bound THEN 'Below Income Band'
        WHEN ci.total_sales BETWEEN ci.ib_lower_bound AND ci.ib_upper_bound THEN 'Within Income Band'
        ELSE 'Above Income Band'
    END AS income_status,
    NULLIF(ci.total_sales, 0) AS normalized_sales
FROM 
    CustomerIncome ci
WHERE 
    ci.sales_rank <= 10
ORDER BY 
    ci.cd_gender, ci.total_sales DESC;
