
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr_order_number) AS catalog_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
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
    WHERE 
        cd.cd_marital_status = 'M'
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN ib.ib_lower_bound < 30000 THEN 'Low'
            WHEN ib.ib_upper_bound BETWEEN 30000 AND 60000 THEN 'Medium'
            ELSE 'High'
        END AS income_category
    FROM 
        income_band ib
),
RankedCustomers AS (
    SELECT 
        cr.c_customer_id,
        cr.total_returns,
        cd.cd_gender,
        ir.income_category,
        ROW_NUMBER() OVER (PARTITION BY ir.income_category ORDER BY cr.total_returns DESC) AS rank
    FROM 
        CustomerReturns cr
    JOIN 
        customer_demographics cd ON cr.c_customer_id = cd.cd_demo_sk
    JOIN 
        IncomeRanges ir ON cd.cd_income_band_sk = ir.ib_income_band_sk
)
SELECT 
    rc.c_customer_id,
    rc.total_returns,
    rc.cd_gender,
    rc.income_category
FROM 
    RankedCustomers rc
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.income_category, rc.total_returns DESC;

WITH RecursiveDate AS (
    SELECT 
        d.d_date,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_date) AS day_of_year
    FROM 
        date_dim d
),
SalesSummary AS (
    SELECT 
        rd.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ss.ss_sales_price) AS store_sales,
        SUM(cs.cs_sales_price) AS catalog_sales,
        SUM(ws.ws_sales_price + cs.cs_sales_price + ss.ss_sales_price) AS overall_sales
    FROM 
        RecursiveDate rd
    LEFT JOIN 
        web_sales ws ON rd.d_date = (SELECT d_date FROM date_dim WHERE d_date_sk = ws.ws_sold_date_sk)
    LEFT JOIN 
        catalog_sales cs ON rd.d_date = (SELECT d_date FROM date_dim WHERE d_date_sk = cs.cs_sold_date_sk)
    LEFT JOIN 
        store_sales ss ON rd.d_date = (SELECT d_date FROM date_dim WHERE d_date_sk = ss.ss_sold_date_sk)
    GROUP BY 
        rd.d_year
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.store_sales,
    ss.catalog_sales,
    ss.overall_sales,
    CASE 
        WHEN ss.total_sales > 1000000 THEN 'High Performer'
        WHEN ss.total_sales BETWEEN 500000 AND 1000000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    SalesSummary ss
ORDER BY 
    ss.d_year;
