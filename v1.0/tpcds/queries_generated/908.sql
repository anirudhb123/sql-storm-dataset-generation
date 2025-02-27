
WITH CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopReturningCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
    WHERE 
        cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
    ORDER BY 
        cr.total_return_amount DESC
    LIMIT 100
), 
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), 
SalesRanked AS (
    SELECT 
        d_year,
        d_month_seq,
        total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        MonthlySales
    WHERE 
        total_sales IS NOT NULL
)
SELECT 
    trc.sr_customer_sk,
    trc.cd_gender,
    trc.cd_marital_status,
    trc.cd_education_status,
    trc.cd_purchase_estimate,
    ms.d_year,
    ms.d_month_seq,
    ms.total_sales,
    sr.sales_rank
FROM 
    TopReturningCustomers trc
LEFT JOIN 
    SalesRanked sr ON trc.cd_purchase_estimate = sr.total_sales
LEFT JOIN 
    MonthlySales ms ON sr.d_year = ms.d_year AND sr.d_month_seq = ms.d_month_seq
WHERE 
    trc.cd_gender IS NOT NULL
ORDER BY 
    trc.total_return_amount DESC, ms.total_sales DESC;
