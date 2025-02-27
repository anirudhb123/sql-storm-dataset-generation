
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM 
        customer_demographics
    WHERE 
        cd_credit_rating IS NOT NULL
),
ReturnStatistics AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    coalesce(cd.cd_gender, 'Unknown') AS gender,
    coalesce(cd.cd_marital_status, 'Not Specified') AS marital_status,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rt.return_count, 0) AS return_count,
    COALESCE(rt.total_return_amt, 0) AS total_return_amt
FROM 
    customer c
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk AND rs.sales_rank = 1
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    ReturnStatistics rt ON c.c_customer_sk = rt.sr_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
    AND (cd.cd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000) OR cd.cd_income_band_sk IS NULL)
ORDER BY 
    total_sales DESC, c.c_last_name ASC;
